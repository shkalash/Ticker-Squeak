//
//  ChecklistItemState.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//

import Foundation


/// Represents the persisted state for a single checklist item.
struct ChecklistItemState: Codable, Identifiable , Equatable {
    let id: String // Corresponds to the ChecklistItem's ID
    var isChecked: Bool = false
    var userText: String = ""
    var imageFileNames: [String] = []
}

/// Represents the complete, persisted state for a single checklist instance.
struct ChecklistState: Codable , Equatable {
    /// The date this checklist state was last modified.
    var lastModified: Date
    /// A dictionary mapping each item's ID to its individual state.
    var itemStates: [String: ChecklistItemState]
}

/// Defines an interface for loading and saving the user's progress on a checklist.
protocol ChecklistStateManaging {
    /// Asynchronously loads the saved state for a checklist identified by its name.
    /// - Parameter checklistName: The identifier for the checklist (e.g., "pre-market-checklist").
    /// - Returns: An array of `ChecklistItemState` objects or `nil` if no state is saved.
    func loadState(forChecklistName checklistName: String) async -> ChecklistState?
    
    /// Asynchronously saves the current state for a checklist.
    /// - Parameters:
    ///   - state: The dictionary of `ChecklistIemState` to save.
    ///   - checklistName: The identifier for the checklist.
    func saveState(_ state: ChecklistState, forChecklistName checklistName: String) async
}
