//
//  ListSettingsViewModel.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation
import Combine

/// The ViewModel for the ListSettingsView, managing the state for list behavior settings.
@MainActor
class ListSettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties for the UI
    
    /// The cooldown in seconds before a hidden ticker can reappear.
    @Published var hidingTimeout: TimeInterval = 300
    
    /// The time of day when the snooze list is automatically cleared.
    @Published var snoozeClearTime: Date = Date()
    
    // MARK: - Private Properties
    
    private let settingsManager: SettingsManaging
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    init(dependencies: any AppDependencies) {
        self.settingsManager = dependencies.settingsManager
        
        // Subscribe to the global settings publisher.
        settingsManager.settingsPublisher
            .sink { [weak self] newSettings in
                // Update the local published properties whenever the global settings change.
                self?.hidingTimeout = newSettings.hidingTimout
                self?.snoozeClearTime = newSettings.snoozeClearTime
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Intents
    
    /// Updates the ticker removal delay in the global settings.
    func setHideTimout(to timeout: TimeInterval) {
        settingsManager.modify { settings in
            settings.hidingTimout = timeout
        }
    }
    
    /// Updates the daily snooze clear time in the global settings.
    func setSnoozeClearTime(to date: Date) {
        settingsManager.modify { settings in
            settings.snoozeClearTime = date
        }
    }
}
