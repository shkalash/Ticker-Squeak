//
//  NotificationSettingsViewModel.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation
import Combine
import UserNotifications

@MainActor
class NotificationSettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties for the UI
    @Published private(set) var notificationMethod: NotificationMethod = .none
    @Published private(set) var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    /// A computed property that determines if the user should be shown the
    /// option to request notification permissions.
    var shouldShowPermissionRequest: Bool {
        // Only show the request UI if desktop notifications are enabled
        // AND the permission status is currently not determined.
        return notificationMethod.contains(.desktop) && permissionStatus == .notDetermined
    }
    
    // MARK: - Private Properties
    private let settingsManager: SettingsManaging
    private let notificationsHandler: NotificationHandling
    private var cancellables = Set<AnyCancellable>()
    
    init(dependencies: any AppDependencies) {
        self.settingsManager = dependencies.settingsManager
        self.notificationsHandler = dependencies.notificationsHandler
        
        // Subscribe to settings changes to get the latest notification method.
        settingsManager.settingsPublisher
            .map(\.notificationMethod)
            .removeDuplicates()
            .assign(to: &$notificationMethod)
            
        // Subscribe to the handler's status publisher to get live updates on permissions.
        notificationsHandler.authorizationStatus
            .assign(to: &$permissionStatus)
    }
    
    // MARK: - Public Intents
    
    /// Updates the user's preferred notification methods in the global settings.
    func setNotificationMethod(to newMethod: NotificationMethod) {
        settingsManager.modify { settings in
            settings.notificationMethod = newMethod
        }
    }
    
    /// Initiates a request for system-level notification permissions.
    func requestPermission() {
        notificationsHandler.requestPermission()
    }
}
