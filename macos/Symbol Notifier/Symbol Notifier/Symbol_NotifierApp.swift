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

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .onAppear {
                    viewModel.requestNotificationPermission()
                    viewModel.startServer()
                }
        }
    }
}
