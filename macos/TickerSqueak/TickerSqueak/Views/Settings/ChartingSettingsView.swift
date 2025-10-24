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
            Divider().padding(.vertical, 4)
            OneOptionSettingsForm(settings: settingsBinding.oneOption)
            Divider().padding(.vertical, 4)
            TradingViewSettingsForm(
                settings: settingsBinding.tradingView,
                hasAccessToAccessibilityAPI: viewModel.hasAccessToAccessibilityAPI,
                onRequestAccess: { viewModel.requestAccessibilityPermission() }
            )
            Divider().padding(.vertical, 4)
            TC2000SettingsForm(settings: settingsBinding.tc2000)
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

private struct TC2000SettingsForm: View {
    @Binding var settings: TC2000Settings
    @State private var isTesting = false
    
    var body: some View {
        HStack(alignment: .center){
            VStack(alignment: .leading, spacing: 15){
                Image("tc2000").resizable().scaledToFit().frame(width: 50)
            }
            VStack(alignment: .leading){
                HStack {
                    Toggle("Enable TC2000 Bridge", isOn: $settings.isEnabled)
                    .onChange(of: settings.isEnabled) { isEnabled in
                        if isEnabled { preflightLocalNetwork() }
                    }
                    Button("Grant Local Network", action: preflightLocalNetwork)
                        .disabled(!settings.isEnabled || settings.host.isEmpty || settings.port == 0)
                }
                HStack {
                    Text("Host:")
                    TextField("10.211.55.3", text: $settings.host).frame(width: 150)
                    Text("Port:")
                    TextField("5055", value: $settings.port, formatter: NumberFormatter()).frame(width: 70)
                    Button("Test Connection", action: testConnection).disabled(settings.port == 0 || settings.host.isEmpty)
                }
                .disabled(!settings.isEnabled)
            }
        }
        .onChange(of: settings.isEnabled) { isEnabled in
            // When enabling at runtime, trigger a silent preflight to surface the Local Network prompt
            if isEnabled { preflightLocalNetwork() }
        }
        
    }
    
    private func preflightLocalNetwork() {
        guard settings.isEnabled else { return }
        guard !settings.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, settings.port > 0 else { return }
        let urlString = "http://\(settings.host):\(settings.port)/health"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 1.5)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }

    private func testConnection() {
        guard settings.isEnabled else { return }
        isTesting = true
        let urlString = "http://\(settings.host):\(settings.port)/health"
        guard let url = URL(string: urlString) else {
            ErrorManager.shared.report(AppError.chartUrlError(data: "Invalid TC2000 bridge URL: \(urlString)"))
            isTesting = false
            return
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 2.0)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { _, response, error in
            defer { isTesting = false }
            if let _ = error {
                let msg = "Couldn’t reach TC2000 bridge. Verify VM networking, and that the bridge app and TC2000 are running."
                ErrorManager.shared.report(AppError.networkError(description: msg), level: .warning)
                return
            }
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                ErrorManager.shared.report(AppError.serverError(code: http.statusCode), level: .warning)
                return
            }
            DispatchQueue.main.async {
                ToastManager.shared.show(Toast(style: .success, message: "TC2000 bridge reachable", duration: 2, sound: ""))
            }
        }.resume()
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
        .frame(width: 500)
}
