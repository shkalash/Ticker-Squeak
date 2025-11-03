//
//  PreMarketLogModel.swift
//  TickerSqueak
//
//  Created for SwiftData migration
//

import Foundation
import SwiftData

@Model
final class PreMarketLogModel {
    @Attribute(.unique) var logDate: Date // Date for the log entry (normalized to start of day)
    var stateData: Data // Stores ChecklistState as JSON
    
    init(date: Date, state: ChecklistState) {
        // Normalize date to start of day for uniqueness
        let calendar = Calendar.current
        self.logDate = calendar.startOfDay(for: date)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.stateData = (try? encoder.encode(state)) ?? Data()
    }
    
    static func normalizedDate(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    var state: ChecklistState {
        get {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return (try? decoder.decode(ChecklistState.self, from: stateData)) ?? ChecklistState(lastModified: logDate, itemStates: [:])
        }
        set {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            stateData = (try? encoder.encode(newValue)) ?? Data()
        }
    }
}

