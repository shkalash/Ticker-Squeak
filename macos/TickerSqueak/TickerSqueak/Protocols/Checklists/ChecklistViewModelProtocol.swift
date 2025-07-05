//
//  ChecklistViewModelProtocol.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//

import Foundation
import Combine
import AppKit
import SwiftUI

/// Defines the base interface for a view model that drives any checklist view.
@MainActor
protocol ChecklistViewModelProtocol: ObservableObject , PickerOptionsProviding {
    // MARK: - Published State for the View
    var title: String { get }
    var checklist: Checklist? { get }
    var itemStates: [String: ChecklistItemState] { get }
    var isLoading: Bool { get }
    var error: Error? { get set }
    var expandedSectionIDs: Set<String> { get set }
    
    // MARK: - Actions from the View
    
    /// Loads the checklist template and its most recent state.
    func load() async
    
    /// Handles pasting new images, persisting them, and updating the state.
    func savePastedImages(_ images: [NSImage], forItemID itemID: String) async
    
    /// Handles deleting a persisted image and updating the state.
    func deletePastedImage(filename: String, forItemID itemID: String)
    
    /// Generates a report and presents a save panel to the user for exporting.
    func generateAndExportReport() async
    
    /// Expands all collapsible sections in the checklist.
    func expandAllSections()
    
    /// Collapses all collapsible sections in the checklist.
    func collapseAllSections()
    
    func binding(for itemID: String) -> Binding<ChecklistItemState>
}

/// A specialized ViewModel protocol for checklists that have a "New Day" workflow.
@MainActor
protocol PreMarketChecklistViewModelProtocol: ChecklistViewModelProtocol {
    func startNewDay() async
}

/// A specialized ViewModel protocol for the Trade Idea checklist.
@MainActor
protocol TradeChecklistViewModelProtocol: ChecklistViewModelProtocol {
    var tradeIdea: TradeIdea { get }
    
    /// Opens the current ticker in the charting service.
    func openInChartingService()
    
    /// Updates the idea's status.
    func updateStatus(to newStatus: IdeaStatus)
}
