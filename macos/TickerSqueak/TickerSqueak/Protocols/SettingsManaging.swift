//
//  SettingsManaging.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Combine
import Foundation

protocol SettingsManaging {
    /// Publishes the complete, up-to-date settings object whenever a change occurs.
    var settingsPublisher: AnyPublisher<AppSettings, Never> { get }
    
    /// Provides the most recent snapshot of the settings.
    var currentSettings: AppSettings { get }

    /// Safely modifies the current settings and triggers persistence.
    /// This is the primary method for making changes.
    func modify(_ block: (inout AppSettings) -> Void)
}
