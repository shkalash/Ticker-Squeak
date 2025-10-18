//
//  TickerSqueakAppDelegate.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/11/25.
//


import Cocoa
import SwiftUI
import UserNotifications

// MARK: - App Delegate for handling quit events , and notification handling
class TickerSqueakAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var powerManager: ExtendedPowerManager?
    private var chartingService: ChartingService?
    private var tickerStore: TickerStoreManaging?
    private var snoozeManager: SnoozeManaging?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup signal handlers when app finishes launching
        SignalHandler.shared.setupSignalHandlers()
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        print("TickerSqueak is preparing to quit - cleaning up...")
        
        // Clean up power management
        powerManager?.allowAllSleep()
        
        // Add any other cleanup here
        // For example: stop servers, save data, etc.
        
        print("TickerSqueak cleanup completed")
        return .terminateNow
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("TickerSqueak is terminating")
        // Final cleanup - this is the last chance
        powerManager?.allowAllSleep()
    }
    
    // Call this to set the power manager reference
    func setPowerManager(_ pm: ExtendedPowerManager) {
        self.powerManager = pm
    }
    
    // Call this to set dependencies for notification handling
    @MainActor func setDependencies(_ container: any AppDependencies) {
        self.chartingService = container.chartingService
        self.tickerStore = container.tickerStore
        self.snoozeManager = container.snoozeManager
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let ticker = response.notification.request.content.userInfo[TickerNotificationAction.tickerUserInfoKey] as? String else {
            completionHandler()
            return
        }
        
        switch response.actionIdentifier {
        case TickerNotificationAction.openChart:
            handleOpenChart(ticker: ticker)
            
        case TickerNotificationAction.snooze:
            handleSnooze(ticker: ticker)
            
        default:
            break
        }
        
        completionHandler()
    }
    
    private func handleOpenChart(ticker: String) {
        Task { @MainActor in
            tickerStore?.markAsRead(id: ticker)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.chartingService?.open(ticker: ticker)
        }
    }
    
    private func handleSnooze(ticker: String) {
        snoozeManager?.setSnooze(for: ticker, isSnoozed: true)
    }
}
