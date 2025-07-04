//
//  TradeIdea.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//

import Foundation

struct TradeIdea: Identifiable, Codable, Hashable , Equatable {
    // Core Identity
    let id: UUID
    let ticker: String
    let createdAt: Date // When the idea was first created

    // At-a-Glance / List View Data
    var direction: TickerItem.Direction
    var status: IdeaStatus
    var decisionAt: Date? // Timestamp for when status changes from .idea

    // The full checklist state
    var checklistState: ChecklistState
}

enum IdeaStatus: String, Codable {
    case idea     // Default state, still being considered
    case taken    // The trade was executed
    case rejected // The idea was considered but not taken
}
