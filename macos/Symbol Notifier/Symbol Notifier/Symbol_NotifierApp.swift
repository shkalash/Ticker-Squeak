//
//  Symbol_NotifierApp.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/21/25.
//

import SwiftUI
import UserNotifications
import AppKit
@main
struct Symbol_NotifierApp: App {
    static let DEFAULT_SERVER_PORT = 4113
    @StateObject private var viewModel = SymbolNotifierViewModel()
    @StateObject var tvSettingsViewModel = TVViewModel()
    @StateObject var oneOptionViewModel = OneOptionViewModel()
    @StateObject private var errorManager = ErrorManager.shared
    let windowName = "io.shkalash.SymbolNotifier"
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(viewModel: viewModel , tvSettingsViewModel: tvSettingsViewModel , oneOptionViewModel: oneOptionViewModel)
                    .background(WindowAccessor { window in
                        // Load saved frame
                        if let frameString = UserDefaults.standard.string(forKey: windowName) {
                            let frame = NSRectFromString(frameString)
                            window.setFrame(frame, display: true)
                        } else {
                            window.setContentSize(NSSize(width: 400, height: 500))
                        }
                        
                        // Save frame on move/resize
                        NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: window, queue: .main) { _ in
                            UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: windowName)
                        }
                        NotificationCenter.default.addObserver(forName: NSWindow.didEndLiveResizeNotification, object: window, queue: .main) { _ in
                            UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: windowName)
                        }
                    })
                
                    .frame(minWidth: 300, minHeight: 400)
                    .onAppear {
                        tvSettingsViewModel.requestAccess()
                        viewModel.requestNotificationPermission()
                        viewModel.startServer()
                    }
                
                // --- Error Dialog Overlay ---
                // This part overlays the error dialog on top of your main content.
                if let currentError = errorManager.currentError {
                    // A semi-transparent background to dim the main content.
                    Color.black.opacity(0.4).ignoresSafeArea()
                    
                    // The error dialog view itself.
                    ErrorDialogView(error: currentError) {
                        // The action to perform when the dialog is dismissed.
                        errorManager.dismissCurrentError()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .animation(.spring(), value: errorManager.currentError != nil)
        }
    }
}
