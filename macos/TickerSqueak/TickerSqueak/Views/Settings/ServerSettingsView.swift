//
//  ServerSettingsView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import SwiftUI

// The main, internal view for all server-related settings.
struct ServerSettingsView_Content: View {
    
    @StateObject private var viewModel: ServerSettingsViewModel

    init(dependencies: any AppDependencies) {
        _viewModel = StateObject(wrappedValue: ServerSettingsViewModel(dependencies: dependencies))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // MARK: - Server Port Section
            Text("Server Port")
                .font(.headline)
            
            HStack {
                Text("Port:")
                TextField("Port", text: $viewModel.editedPortText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
            
            HStack {
                Button(action: viewModel.revertPortChange) {
                    Label("Revert", systemImage: "arrow.uturn.backward")
                }
                .disabled(!viewModel.hasUnappliedChanges)

                Spacer()

                Button(action: viewModel.applyPortChange) {
                    Label("Apply", systemImage: "checkmark.circle.fill")
                }
                .disabled(!viewModel.hasUnappliedChanges)
                .keyboardShortcut(.defaultAction)
            }
            
            Divider()
            
            // MARK: - Server Status Section
            Text("Server Status")
                .font(.headline)

            HStack(spacing: 12) {
                Circle()
                    .fill(viewModel.isServerRunning ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(viewModel.isServerRunning ? "Listening on Port : " + String(format: "%d", viewModel.currentServerPort) : "Stopped")
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    if viewModel.isServerRunning {
                        viewModel.stopServer()
                    } else {
                        viewModel.startServer()
                    }
                }) {
                    Label(
                        viewModel.isServerRunning ? "Stop" : "Start",
                        systemImage: viewModel.isServerRunning ? "power.circle" : "figure.run.square.stack"
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .foregroundColor(viewModel.isServerRunning ? .red : .cyan)
                   
                }.buttonStyle(.borderless)
            }
        }
        .padding()
    }
}


/// The public-facing "loader" view for the server settings.
struct ServerSettingsView: View {
    @EnvironmentObject private var dependencies: DependencyContainer

    var body: some View {
        ServerSettingsView_Content(dependencies: dependencies)
    }
}

#Preview {
    let previewDependencies = PreviewDependencyContainer()
    
    return ServerSettingsView_Content(dependencies: previewDependencies)
        .environmentObject(previewDependencies)
        .frame(width: 350)
}
