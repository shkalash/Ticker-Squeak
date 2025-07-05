//
//  DefaultChecklistStateManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation

/// The default implementation for managing the state of a checklist.
/// It uses a generic PersistenceHandling service to load and save the state data.
class DefaultChecklistStateManager: ChecklistStateManaging {

    /// A dependency on the persistence protocol, not a concrete type.
    private let persistence: PersistenceHandling

    /// Initializes the state manager with a persistence handler.
    /// In your app's startup code, you would pass an instance of `UserDefaultsPersistenceHandler`.
    init(persistence: PersistenceHandling) {
        self.persistence = persistence
    }

    /// Loads the saved state by creating the correct `PersistenceKey` and calling the persistence service.
    func loadState(forChecklistName checklistName: String) async -> ChecklistState? {
        // Create the specific, type-safe key for this checklist.
        let key = PersistenceKey<ChecklistState>.checklistState(forName: checklistName)
        
        // Use the `load(object:)` method for Codable types from your protocol.
        return persistence.load(for: key)
    }

    /// Saves the current state by creating the correct `PersistenceKey` and calling the persistence service.
    func saveState(_ state: ChecklistState, forChecklistName checklistName: String) async {
        let key = PersistenceKey<ChecklistState>.checklistState(forName: checklistName)
        
        // Use the `save(object:)` method for Codable types from your protocol.
        persistence.save(object: state, for: key)
    }
}
