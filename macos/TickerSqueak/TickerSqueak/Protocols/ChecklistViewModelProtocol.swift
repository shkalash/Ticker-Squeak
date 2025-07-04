//
//  ChecklistViewModelProtocol.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation
import Combine // For @Published and ObservableObject
import AppKit
/// Defines the interface for the view model that drives a checklist view.
/// It orchestrates data fetching and state updates.
@MainActor
protocol ChecklistViewModelProtocol: ObservableObject {
    // MARK: - Published State for the View
    var title: String { get }
    var checklist: Checklist? { get }
    var itemStates: [String: ChecklistItemState] { get }
    var isLoading: Bool { get }
    var error: Error? { get set }
    var expandedSectionIDs: Set<UUID> {get set}
    // MARK: - Actions from the View
    
    /// Loads the checklist template and its most recent state.
    func load() async
    
    /// Updates the state for a single checklist item and triggers a save.
    /// - Parameter itemID: The ID of the item being updated.
    /// - Parameter newState: The complete new state for that item.
    func updateItemState(itemID: String, newState: ChecklistItemState)
    
    /// Handles pasting a new image, persisting it, and updating the state.
    /// - Parameter image: The `NSImage` that was pasted.
    /// - Parameter itemID: The ID of the image item to associate with.
    func savePastedImages(_ images: [NSImage], forItemID itemID: String) async

    /// Generates a report and presents a save panel to the user for exporting.
    func generateAndExportReport() async
}

/// A specialized ViewModel protocol for checklists that have a "New Day" workflow.
@MainActor
protocol PreMarketChecklistViewModelProtocol: ChecklistViewModelProtocol {
    func startNewDay() async
}
