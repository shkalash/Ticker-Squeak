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
    func setDependencies(chartingService: ChartingService, tickerStore: TickerStoreManaging) {
        self.chartingService = chartingService
        self.tickerStore = tickerStore
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Only handle our custom action - this prevents app activation
        guard response.actionIdentifier == "OPEN_CHART" else {
            completionHandler()
            return
        }
        
        // Extract the ticker from the notification's userInfo
        guard let ticker = response.notification.request.content.userInfo["ticker"] as? String else {
            completionHandler()
            return
        }
        
        // Mark the ticker as read in the ticker store
        Task { @MainActor in
            tickerStore?.markAsRead(id: ticker)
        }
        
        // Open the chart using the charting service
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.chartingService?.open(ticker: ticker)
        }
        
        completionHandler()
    }
}
