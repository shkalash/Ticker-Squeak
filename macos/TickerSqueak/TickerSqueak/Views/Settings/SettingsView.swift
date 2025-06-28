//
//  SettingsView 2.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import SwiftUI

// This is the internal content view that contains the actual layout.
struct SettingsView_Content: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    // It accepts any object conforming to AppDependencies, making it flexible.
    private let dependencies: any AppDependencies
    
    init(dependencies: any AppDependencies) {
        self.dependencies = dependencies
    }
    var body: some View {
        VStack() {
            // The custom tab picker for navigation
            IconTabPicker(selection: $viewModel.selectedTab, options: [
                PickerOption(label: "General", imageName: "gearshape.fill", tag: 0),
                PickerOption(label: "Server", imageName: "dot.radiowaves.left.and.right", tag: 1),
                PickerOption(label: "Charting", imageName: "chart.xyaxis.line", tag: 2),
            ])
            .padding([.horizontal])
            .padding(.bottom, 8)
            
            Divider()
            ScrollView {
                // The switch statement now passes the dependencies down to the
                // specific content view for each tab.
                switch viewModel.selectedTab {
                    case 0:
                        // MARK: - General Settings Tab
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ListSettingsView_Content(dependencies: dependencies)
                            Divider()
                            NotificationSettingsView_Content(dependencies: dependencies)
                            Divider()
                            NotificationAudioSettingsView_Content(dependencies: dependencies)
                        }.padding()
                    case 1:
                        ServerSettingsView_Content(dependencies: dependencies)
                            .padding()
                    case 2:
                        ChartingSettingsView_Content(dependencies: dependencies)
                            .padding()
                    default:
                        EmptyView()
                }
            }
        }
    }
}



/// The public-facing "loader" view for the settings screen.
struct SettingsView: View {
    // It reads the REAL DependencyContainer from the environment.
    @EnvironmentObject private var dependencies: DependencyContainer

    var body: some View {
        // It then passes those dependencies into the content view.
        SettingsView_Content(dependencies: dependencies)
    }
}

#Preview {
    // 1. Create the mock dependency container for the preview.
    let previewDependencies = PreviewDependencyContainer()
    
    // 2. Directly create the `SettingsView_Content` and pass the mock dependencies
    //    into its initializer. This is the key to making the preview work.
    return SettingsView_Content(dependencies: previewDependencies)
        // 3. Still provide the environmentObject for any potential grandchild views.
        .environmentObject(previewDependencies)
}
