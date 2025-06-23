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
    let windowName = "io.shkalash.SymbolNotifier"
    // TODO: errors.
    var body: some Scene {
        WindowGroup {
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
        }
    }
}
