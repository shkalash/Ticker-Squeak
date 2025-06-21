//
//  Symbol_NotifierApp.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/21/25.
//

import SwiftUI
import UserNotifications

@main
struct Symbol_NotifierApp: App {
    @StateObject private var viewModel = SymbolNotifierViewModel()
    let windowName = "io.shkalash.SymbolNotifier"
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
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
                    viewModel.requestNotificationPermission()
                    viewModel.startServer()
                }
        }
    }
}
