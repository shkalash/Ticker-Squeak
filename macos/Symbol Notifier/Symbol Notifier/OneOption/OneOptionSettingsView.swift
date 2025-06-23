//
//  OneOptionSettingsView.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/24/25.
//


import SwiftUI

/// A SwiftUI view that provides UI controls for managing OneOptionSettings.
struct OneOptionSettingsView: View {
    
    /// The view model that manages the settings data and logic.
    @ObservedObject var viewModel: OneOptionViewModel

    var body: some View {
        // Main container with vertical alignment and spacing, similar to the example.
        VStack(alignment: .leading, spacing: 16) {
            
            // --- Header ---
            Text("OneOption Integration")
                .font(.headline)
            
            // --- Main Toggle ---
            // This toggle controls the master switch for the automation.
            Toggle("Enable OneOption Automation", isOn: $viewModel.settings.enableOneOptionAutomation)
            
            Divider()
            
            // --- Settings Group ---
            // This group contains all the detailed settings.
            // It will be disabled entirely if the main automation toggle is off.
            Group {
                HStack {
                    Text("Time Frame")
                    Spacer() // Pushes the picker to the right
                    Picker("", selection: $viewModel.settings.timeFrame) {
                        // Iterate over the custom-sorted cases to match requirements.
                        ForEach(TimeFrame.sortedCases, id: \.self) { timeFrame in
                            Text(timeFrame.displayName).tag(timeFrame)
                        }
                    }
                    .frame(width: 120) // Give the picker a fixed width.
                }

                HStack {
                    Text("Chart Group")
                    Spacer() // Pushes the picker to the right
                    Picker("", selection: $viewModel.settings.chartGroup) {
                        // Iterate over all possible ChartGroup cases.
                        ForEach(ChartGroup.allCases, id: \.self) { group in
                            Text(group.displayName).tag(group)
                        }
                    }
                    .frame(width: 120) // Give the picker a fixed width for consistent layout.
                }
            }
            // The entire Group is disabled based on the state of the main toggle.
            .disabled(!viewModel.settings.enableOneOptionAutomation)
            
            Spacer() // Pushes all content to the top
        }
        .padding() // Add some padding around the whole view.
    }
}

// Simpler, preferred for macOS 14+
#Preview {
    OneOptionSettingsView(viewModel: OneOptionViewModel())
        .frame(width: 400, height: 200)
}
