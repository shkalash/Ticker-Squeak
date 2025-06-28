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
                .frame(minWidth: 300, minHeight: 400)
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
// TODO: Visual design for toasts and dialogs
// TODO: View doesn't correctly adjust to window size
// TODO: Make tabs drop the description and show only image if too small
// TODO: Minor spacing and alignments in settings views, maybe replace the icon picker tab to a sidebar or something else.
// TODO: Ticker Image?
