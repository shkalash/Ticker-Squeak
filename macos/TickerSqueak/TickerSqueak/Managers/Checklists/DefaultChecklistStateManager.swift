//
//  DefaultChecklistStateManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation
import SwiftData

/// The default implementation for managing the state of a checklist.
/// It uses SwiftData to load and save the state data.
class DefaultChecklistStateManager: ChecklistStateManaging {

    /// A dependency on the ModelContext for SwiftData operations.
    private let modelContext: ModelContext

    /// Initializes the state manager with a ModelContext.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Loads the saved state from SwiftData.
    func loadState(forChecklistName checklistName: String) async -> ChecklistState? {
        let descriptor = FetchDescriptor<ChecklistStateModel>(
            predicate: #Predicate { $0.checklistName == checklistName }
        )
        
        do {
            let models = try modelContext.fetch(descriptor)
            return models.first?.state
        } catch {
            print("[DefaultChecklistStateManager] Error loading state: \(error)")
            return nil
        }
    }

    /// Saves the current state to SwiftData.
    func saveState(_ state: ChecklistState, forChecklistName checklistName: String) async {
        let descriptor = FetchDescriptor<ChecklistStateModel>(
            predicate: #Predicate { $0.checklistName == checklistName }
        )
        
        do {
            let models = try modelContext.fetch(descriptor)
            if let existingModel = models.first {
                existingModel.state = state
            } else {
                let newModel = ChecklistStateModel(checklistName: checklistName, state: state)
                modelContext.insert(newModel)
            }
            try modelContext.save()
        } catch {
            print("[DefaultChecklistStateManager] Error saving state: \(error)")
        }
    }
}
