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
    @StateObject private var dialogManager = DialogManager.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencies)
                .persistentFrame(forKey: windowName, persistence: dependencies.persistenceHandler)
                .environmentObject(dialogManager)
                .onAppear{
                    // Server must be started on app run
                    dependencies.tickerProvider.start()
                }
            #if DEBUG
                .withDebugOverlay()
                .environmentObject(dependencies)
            #endif
        }
    }
}

