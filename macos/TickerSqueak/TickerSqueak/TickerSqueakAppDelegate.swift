//
//  TickerSqueakAppDelegate.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/11/25.
//


import Cocoa
import SwiftUI

// MARK: - App Delegate for handling quit events
class TickerSqueakAppDelegate: NSObject, NSApplicationDelegate {
    private var powerManager: ExtendedPowerManager?
    
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
}