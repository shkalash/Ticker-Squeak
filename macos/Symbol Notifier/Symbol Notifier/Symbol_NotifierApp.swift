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
                .background(WindowAccessor { window in
                    window.setContentSize(NSSize(width: 400, height: 500))
                    window.center()
                })
                .frame(minWidth: 300, minHeight: 400)
                .onAppear {
                    viewModel.requestNotificationPermission()
                    viewModel.startServer()
                }
        }
    }
}
