//
//  NotificationSettingsView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import SwiftUI
import UserNotifications

// The main, internal view for the notification settings.
struct NotificationSettingsView_Content: View {
    @StateObject private var viewModel: NotificationSettingsViewModel

    init(dependencies: any AppDependencies) {
        _viewModel = StateObject(wrappedValue: NotificationSettingsViewModel(dependencies: dependencies))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notification Method")
                .font(.headline)

            // Toggle for In-App Notifications
            Toggle(isOn: binding(for: .app)) {
                Text("In-App Banners")
            }
            
            // Toggle for Desktop Notifications
            HStack {
                Toggle(isOn: binding(for: .desktop)) {
                    Text("Desktop Notifications")
                }
                
                // The status icons and button only appear when the user has enabled the toggle
                if viewModel.notificationMethod.contains(.desktop) {
                    Spacer()
                    
                    switch viewModel.permissionStatus {
                        case .authorized, .provisional, .ephemeral:
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                                .help("Permission granted")
                            
                        case .denied:
                            Image(systemName: "xmark.shield.fill")
                                .foregroundColor(.red)
                                .help("Permission denied. Please change in System Settings.")
                            
                        case .notDetermined:
                            HStack {
                                Image(systemName: "questionmark.diamond")
                                    .foregroundColor(.yellow)
                                    .help("Permission required")
                                    .padding(.horizontal)
                                Button(action: viewModel.requestPermission) {
                                    Image(systemName: "lock.open.fill")
                                }
                                .help("Request permission")
                            }
                            
                        @unknown default:
                            EmptyView()
                    }
                }
            }
        }
    }
    
    /// Creates a binding for a specific notification method. Toggling it on or off
    /// correctly updates the OptionSet in the ViewModel.
    private func binding(for method: NotificationMethod) -> Binding<Bool> {
        Binding<Bool>(
            get: { viewModel.notificationMethod.contains(method) },
            set: { isEnabled in
                var newMethod = viewModel.notificationMethod
                if isEnabled {
                    newMethod.insert(method)
                } else {
                    newMethod.remove(method)
                }
                viewModel.setNotificationMethod(to: newMethod)
            }
        )
    }
}

/// A helper view to display the permission status and a request button.
private struct PermissionStatusView: View {
    let status: UNAuthorizationStatus
    let onRequest: () -> Void
    
    var body: some View {
        HStack {
            switch status {
            case .notDetermined:
                Text("Requires permission.")
                    .foregroundColor(.secondary)
                Button("Request Access", action: onRequest)
            case .denied:
                Text("Permission Denied.")
                    .foregroundColor(.red)
                // Optionally add a button to guide user to System Settings
            case .authorized, .provisional, .ephemeral:
                Text("Permission Granted.")
                    .foregroundColor(.green)
            @unknown default:
                EmptyView()
            }
        }
    }
}

/// The public-facing "loader" view.
struct NotificationSettingsView: View {
    @EnvironmentObject private var dependencies: DependencyContainer

    var body: some View {
        NotificationSettingsView_Content(dependencies: dependencies)
    }
}

#Preview {
    let previewDependencies = PreviewDependencyContainer()
    
    return NotificationSettingsView_Content(dependencies: previewDependencies)
        .environmentObject(previewDependencies)
        .frame(width: 400)
}
