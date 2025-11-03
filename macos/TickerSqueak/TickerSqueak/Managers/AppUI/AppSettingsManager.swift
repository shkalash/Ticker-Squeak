//
//  StandardSettingsManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Foundation
import Combine
import SwiftData

class AppSettingsManager: SettingsManaging {
    
    // The single source of truth for all app settings.
    @Published private var settings: AppSettings = AppSettings()
    
    private let modelContext: ModelContext
    private var settingsModel: AppSettingsModel?
    private var cancellables = Set<AnyCancellable>()

    var settingsPublisher: AnyPublisher<AppSettings, Never> {
        $settings.eraseToAnyPublisher()
    }
    
    var currentSettings: AppSettings {
        settings
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Load or create the singleton settings model
        loadOrCreateSettings()
        
        // Now, automatically save the settings object back to SwiftData
        // any time it changes.
        $settings
            .dropFirst() // Don't save during initialization
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // Prevent rapid-fire saves
            .sink { [weak self] updatedSettings in
                self?.saveToSwiftData(updatedSettings)
            }
            .store(in: &cancellables)
    }
    
    private func loadOrCreateSettings() {
        let descriptor = FetchDescriptor<AppSettingsModel>(
            predicate: #Predicate { $0.id == "settings" }
        )
        
        do {
            let models = try modelContext.fetch(descriptor)
            if let existingModel = models.first {
                self.settingsModel = existingModel
                self.settings = existingModel.toAppSettings()
            } else {
                // Create default settings
                let defaultModel = AppSettingsModel(settings: AppSettings())
                modelContext.insert(defaultModel)
                try modelContext.save()
                self.settingsModel = defaultModel
                self.settings = defaultModel.toAppSettings()
            }
        } catch {
            print("[AppSettingsManager] Error loading settings: \(error)")
            // Fallback to default
            self.settings = AppSettings()
        }
    }
    
    private func saveToSwiftData(_ appSettings: AppSettings) {
        if let model = settingsModel {
            model.update(from: appSettings)
        } else {
            // Create if it doesn't exist
            let model = AppSettingsModel(settings: appSettings)
            modelContext.insert(model)
            settingsModel = model
        }
        
        do {
            try modelContext.save()
        } catch {
            print("[AppSettingsManager] Error saving settings: \(error)")
        }
    }

    func modify(_ block: (inout AppSettings) -> Void) {
        var newSettings = self.settings
        block(&newSettings)
        self.settings = newSettings
    }
}
