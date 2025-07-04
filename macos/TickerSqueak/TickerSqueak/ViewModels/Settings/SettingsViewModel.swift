//
//  SettingsViewModel.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation
import SwiftUI

/// The ViewModel for the main SettingsView.
/// Its only responsibility is to manage the currently selected settings tab,
/// persisting the selection across app launches.
@MainActor
class SettingsViewModel: ObservableObject {
    
    /// The index of the currently selected tab, persisted in UserDefaults.
    @AppStorage("settingsTabIndex") var selectedTab: Int = 0
}
