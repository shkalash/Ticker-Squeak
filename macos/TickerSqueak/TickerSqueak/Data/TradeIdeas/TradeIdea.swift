//
//  TradeIdea.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//

import Foundation


struct TradeIdea: Identifiable, Codable, Hashable {
    // Core Identity
    let id: UUID
    let ticker: String
    let createdAt: Date

    // "At-a-Glance" Data for the List View
    var direction: TickerItem.Direction // Using your existing Direction enum
    var status: IdeaStatus // The new enum for tracking the idea's outcome
    var quickNotes: String // A one-line summary or thesis for the list row
    var thumbnailImageName: String? // The filename of the primary screenshot

    // The full, detailed checklist state
    var checklistState: ChecklistState
}

// New enum to track the status of a trade idea
enum IdeaStatus: String, Codable {
    case idea     // Default state, still being considered
    case taken    // The trade was executed
    case rejected // The idea was considered but not taken
}
