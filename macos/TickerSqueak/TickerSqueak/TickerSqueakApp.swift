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
    // TODO: Add charting
    // TODO: Rig Toasts
    // TODO: Rig Dialogs
    let windowName = "io.shkalash.TickerSqueak"
    private let dependencies = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencies)
                .persistentFrame(forKey: windowName, persistence: dependencies.persistenceHandler)
                .frame(minWidth: 300, minHeight: 400)
                .withDialogs(manager: DialogManager.shared)
//                .onAppear {
//                    tvSettingsViewModel.requestAccess()
//                    viewModel.requestNotificationPermission()
//                    viewModel.startServer()
//                }
        }
    }
}
