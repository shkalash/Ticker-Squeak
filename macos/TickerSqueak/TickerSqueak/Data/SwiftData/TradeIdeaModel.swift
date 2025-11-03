//
//  TradeIdeaModel.swift
//  TickerSqueak
//
//  Created for SwiftData migration
//

import Foundation
import SwiftData

@Model
final class TradeIdeaModel {
    @Attribute(.unique) var id: UUID
    var ticker: String
    var createdAt: Date
    var directionRawValue: String
    var statusRawValue: String
    var decisionAt: Date?
    var checklistStateData: Data // Stores ChecklistState as JSON
    
    init(idea: TradeIdea) {
        self.id = idea.id
        self.ticker = idea.ticker
        self.createdAt = idea.createdAt
        self.directionRawValue = idea.direction.rawValue
        self.statusRawValue = idea.status.rawValue
        self.decisionAt = idea.decisionAt
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.checklistStateData = (try? encoder.encode(idea.checklistState)) ?? Data()
    }
    
    var direction: TickerItem.Direction {
        get {
            TickerItem.Direction(rawValue: directionRawValue) ?? .none
        }
        set {
            directionRawValue = newValue.rawValue
        }
    }
    
    var status: IdeaStatus {
        get {
            IdeaStatus(rawValue: statusRawValue) ?? .idea
        }
        set {
            statusRawValue = newValue.rawValue
        }
    }
    
    var checklistState: ChecklistState {
        get {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return (try? decoder.decode(ChecklistState.self, from: checklistStateData)) ?? ChecklistState(lastModified: Date(), itemStates: [:])
        }
        set {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            checklistStateData = (try? encoder.encode(newValue)) ?? Data()
        }
    }
    
    func toTradeIdea() -> TradeIdea {
        TradeIdea(
            id: id,
            ticker: ticker,
            createdAt: createdAt,
            direction: direction,
            status: status,
            decisionAt: decisionAt,
            checklistState: checklistState
        )
    }
    
    func update(from idea: TradeIdea) {
        self.ticker = idea.ticker
        self.createdAt = idea.createdAt
        self.direction = idea.direction
        self.status = idea.status
        self.decisionAt = idea.decisionAt
        self.checklistState = idea.checklistState
    }
}



