//
//  ChartingSettingsView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/27/25.
//

import SwiftUI


struct ChartingSettingsView_Content: View {
    @StateObject private var viewModel: ChartingSettingsViewModel

    init(dependencies: any AppDependencies) {
        _viewModel = StateObject(wrappedValue: ChartingSettingsViewModel(dependencies: dependencies))
    }

    var body: some View {
        let settingsBinding = Binding<ChartingSettings>(
            get: { viewModel.chartingSettings },
            set: { viewModel.setChartingSettings($0) }
        )
        
        VStack(alignment: .leading , spacing: 8) {
            Text("Charting Integrations").font(.headline)
            Divider()
            OneOptionSettingsForm(settings: settingsBinding.oneOption)
            Divider()
            TradingViewSettingsForm(
                settings: settingsBinding.tradingView,
                hasAccessToAccessibilityAPI: viewModel.hasAccessToAccessibilityAPI,
                onRequestAccess: { viewModel.requestAccessibilityPermission() }
            )
        }
        // Check for accessibility changes when the view appears.
        .onAppear {
            viewModel.checkAccessibilityStatus()
        }// Re-check accessibility access whenever the app becomes active.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.checkAccessibilityStatus()
        }
    }
}

private struct TradingViewSettingsForm: View {
    @Binding var settings: TradingViewSettings
    let hasAccessToAccessibilityAPI: Bool
    let onRequestAccess: () -> Void
    
    var body: some View {
        HStack(alignment: .center){
            VStack(alignment: .leading, spacing: 15){
                Image("tradingview").resizable().scaledToFit().frame(width: 50)
            }
            VStack(alignment: .leading){
                HStack {
                    Toggle("Enable TradingView Automation", isOn: $settings.isEnabled)
                    Image(systemName: hasAccessToAccessibilityAPI ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .foregroundColor(hasAccessToAccessibilityAPI ? .green : .red)
                    if !hasAccessToAccessibilityAPI {
                        Button(action: onRequestAccess) { Image(systemName: "lock.open.fill") }
                            .buttonStyle(.plain).foregroundColor(.yellow)
                    }
                }
                
                Group {
                    Toggle("Change Active Tab", isOn: $settings.changeTab)
                    Stepper("Switch to Tab #: \(settings.tabNumber)", value: $settings.tabNumber, in: 1...9)
                    Picker("Using Modifier Key:", selection: $settings.tabModifier) {
                        ForEach(ModifierKey.allCases) { Text($0.displayName).tag($0) }
                    }
                }.disabled(!settings.isEnabled)
            }
        }
    }
}

private struct OneOptionSettingsForm: View {
    @Binding var settings: OneOptionSettings
    
    var body: some View {
        HStack(alignment: .center){
            VStack(alignment: .leading, spacing: 15){
                Image("oneoption").resizable().scaledToFit().frame(width: 50)
            }
            VStack(alignment: .leading){
                Toggle("Enable OneOption Automation", isOn: $settings.isEnabled)
                Group {
                    Picker("Chart Group:", selection: $settings.chartGroup) {
                        ForEach(ChartGroup.allCases, id: \.self) { Text($0.displayName).tag($0)
                        }
                    }
                    Picker("Time Frame:", selection: $settings.timeFrame) {
                        ForEach(TimeFrame.sortedCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                }.disabled(!settings.isEnabled)
            }
        }
    }
}

/// The public-facing "loader" view.
struct ChartingSettingsView: View {
    @EnvironmentObject private var dependencies: DependencyContainer
    var body: some View {
        ChartingSettingsView_Content(dependencies: dependencies)
    }
}

#Preview {
    let previewDependencies = PreviewDependencyContainer()
    return ChartingSettingsView_Content(dependencies: previewDependencies)
        .environmentObject(previewDependencies)
        .frame(width: 400)
}
