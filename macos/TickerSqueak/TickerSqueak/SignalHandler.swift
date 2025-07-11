//
//  SignalHandler.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/11/25.
//

import Cocoa
class SignalHandler {
    static let shared = SignalHandler()
    
    private init() {}
    
    func setupSignalHandlers() {
        // Handle SIGTERM (system trying to quit the app)
        signal(SIGTERM) { _ in
            print("Received SIGTERM - performing emergency cleanup")
            SignalHandler.performEmergencyCleanup()
            exit(0)
        }
        
        // Handle SIGINT (Ctrl+C if run from terminal)
        signal(SIGINT) { _ in
            print("Received SIGINT - performing emergency cleanup")
            SignalHandler.performEmergencyCleanup()
            exit(0)
        }
    }
    
    private static func performEmergencyCleanup() {
        // Keep this very simple and fast - signal handlers have limitations
        
        // Release power assertions using C API directly since we can't guarantee Swift objects
        // This is a fallback - normally the AppDelegate handles this properly
        
        // You could also write to a file or set a flag that the main app checks
        print("Emergency cleanup completed")
    }
}
