//
//  StandardSettingsManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Foundation
import Combine

class AppSettingsManager: SettingsManaging {
    
    // The single source of truth for all app settings.
    @Published private var settings: AppSettings
    
    private let persistence: PersistenceHandling
    private var cancellables = Set<AnyCancellable>()

    var settingsPublisher: AnyPublisher<AppSettings, Never> {
        $settings.eraseToAnyPublisher()
    }
    
    var currentSettings: AppSettings {
        settings
    }

    init(persistence: PersistenceHandling) {
        self.persistence = persistence
        
        // On init, load settings from persistence OR create a default object.
        self.settings = persistence.load(for: .appSettings) ?? AppSettings()
        
        // Now, automatically save the settings object back to persistence
        // any time it changes.
        $settings
            .dropFirst() // Don't save during initialization
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // Prevent rapid-fire saves
            .sink { [weak self] updatedSettings in
                self?.persistence.save(object: updatedSettings, for: .appSettings)
            }
            .store(in: &cancellables)
    }

    func modify(_ block: (inout AppSettings) -> Void) {
        var newSettings = self.settings
        block(&newSettings)
        self.settings = newSettings
    }
}
