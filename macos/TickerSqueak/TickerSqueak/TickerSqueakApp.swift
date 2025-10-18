//
//  Ticker_NotifierApp.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/21/25.
//

import SwiftUI
import UserNotifications
import AppKit
@main
struct TickerSqueakApp: App {
    let windowName = "io.shkalash.TickerSqueak"
    private let dependencies = DependencyContainer()
    private let pm = ExtendedPowerManager()
    @StateObject private var dialogManager = DialogManager.shared
    // Create the app delegate
    @NSApplicationDelegateAdaptor(TickerSqueakAppDelegate.self) var appDelegate
    
    init() {
        // Pass the power manager to the app delegate
        appDelegate.setPowerManager(pm)
        // Pass dependencies for notification handling
        appDelegate.setDependencies(dependencies)
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencies)
                .persistentFrame(forKey: windowName, persistence: dependencies.persistenceHandler)
                .environmentObject(dialogManager)
                .onAppear{
                    // Server must be started on app run
                    dependencies.tickerProvider.start()
                    DataMigrator.migrate(settingsManager: dependencies.settingsManager, ignoreManager: dependencies.ignoreManager)
                    pm.preventAllSleep()
                    // Set the notification delegate to enable click handling
                    (dependencies.notificationsHandler as? AppNotificationHandler)?.setNotificationDelegate(appDelegate)
                }
            #if DEBUG
                .withDebugOverlay()
                .environmentObject(dependencies)
            #endif
        }
        
        // Define the new, secondary window for our web view
        Window("Floating SPY", id: "floating-spy") {
            FloatingWebView()
        }
    }
    
}

