//
//  NotificationsHandler.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Foundation
import Combine
import UserNotifications
import AppKit

class AppNotificationHandler: NotificationHandling {

    var authorizationStatus: AnyPublisher<UNAuthorizationStatus, Never> {
        authorizationStatusSubject.eraseToAnyPublisher()
    }
    private let authorizationStatusSubject = CurrentValueSubject<UNAuthorizationStatus, Never>(.notDetermined)
    
    private let OPEN_CHART_ACTION_IDENTIFIER = "OPEN_CHART"
    private let TICKER_ALERT_CATEGORY_IDENTIFIER = "TICKER_ALERT"

    // MARK: - Private Properties
    private let settingsManager: SettingsManaging
    private var cancellables = Set<AnyCancellable>()
    
    init(settingsManager: SettingsManaging) {
        self.settingsManager = settingsManager
        
        // Register notification categories with custom actions
        setupNotificationCategories()
        
        // When the app starts, immediately check the current status.
        checkNotificationPermissionStatus()

        // Any time the app becomes active, re-check the status in case the
        // user changed it in the System Settings.
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkNotificationPermissionStatus()
            }
            .store(in: &cancellables)
    }
    
    func setNotificationDelegate(_ delegate: UNUserNotificationCenterDelegate) {
        UNUserNotificationCenter.current().delegate = delegate
    }
    
    private func setupNotificationCategories() {
        // Create a custom action that doesn't activate the app (no .foreground option)
        let openChartAction = UNNotificationAction(
            identifier: OPEN_CHART_ACTION_IDENTIFIER,
            title: "Open Chart",
            options: [] // No .foreground - this keeps the app in the background
        )
        
        let category = UNNotificationCategory(
            identifier: TICKER_ALERT_CATEGORY_IDENTIFIER,
            actions: [openChartAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
        
    @objc private func checkNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            
            DispatchQueue.main.async {
                if (settings.authorizationStatus == .notDetermined){
                    self?.requestPermission()
                }
                else if (settings.authorizationStatus == .denied){
                    self?.removeDesktopNotifications()
                }
                self?.authorizationStatusSubject.send(settings.authorizationStatus)
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            if !granted {
                ErrorManager.shared.report(AppError.notificationPermissionDenied , level: .warning)
                self?.removeDesktopNotifications()
            }
            if let error = error {
                ErrorManager.shared.report(error)
            }
            // After requesting, re-check and broadcast the new status.
            self?.checkNotificationPermissionStatus()
        }
    }
    
    private func removeDesktopNotifications(){
        self.settingsManager.modify { settings in
            settings.notificationMethod.remove(.desktop)
        }
    }
    
    func showNotification(for ticker: String, isHighPriority: Bool) {
        // Use the app's active state to decide between a toast and a system notification.
        if settingsManager.currentSettings.notificationMethod.contains(.app){
            showToast(for: ticker, isHighPriority: isHighPriority)
        }
        if settingsManager.currentSettings.notificationMethod.contains(.desktop){
            showSystemNotification(for: ticker, isHighPriority: isHighPriority)
        }
    }
    


    private func showSystemNotification(for ticker: String, isHighPriority: Bool) {
        let content = UNMutableNotificationContent()
        content.title = isHighPriority ? "‼️ Ticker Alert ‼️" : "Ticker Alert"
        content.body = ticker
        content.sound = nil
        content.userInfo = ["ticker": ticker]
        content.categoryIdentifier = TICKER_ALERT_CATEGORY_IDENTIFIER // Attach the category with custom actions
        let sound = settingsManager.currentSettings.soundLibrary.getSound(for: isHighPriority ?  .highPriorityAlert : .alert)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        Task {
            await SoundManager.shared.playSoundForNotification(named: sound, cooldown: 2)
        }
    }
    
    private func showToast(for ticker: String, isHighPriority: Bool) {
        let sound = settingsManager.currentSettings.soundLibrary.getSound(for: isHighPriority ?  .highPriorityAlert : .alert)
        let toast : Toast = Toast(style: isHighPriority ? .importantInfo : .info,
                                    message: "Ticker Alert \(ticker)" ,
                                    duration: settingsManager.currentSettings.toastDuration,
                                    sound: sound)
        DispatchQueue.main.async{
            ToastManager.shared.show(toast)
        }
    }
    
}
