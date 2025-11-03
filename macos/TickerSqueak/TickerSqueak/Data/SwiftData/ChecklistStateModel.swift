//
//  ChecklistStateModel.swift
//  TickerSqueak
//
//  Created for SwiftData migration
//

import Foundation
import SwiftData

@Model
final class ChecklistStateModel {
    @Attribute(.unique) var checklistName: String
    var lastModified: Date
    var stateData: Data // Stores ChecklistState as JSON
    
    init(checklistName: String, state: ChecklistState) {
        self.checklistName = checklistName
        self.lastModified = state.lastModified
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.stateData = (try? encoder.encode(state)) ?? Data()
    }
    
    var state: ChecklistState {
        get {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return (try? decoder.decode(ChecklistState.self, from: stateData)) ?? ChecklistState(lastModified: Date(), itemStates: [:])
        }
        set {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            lastModified = newValue.lastModified
            stateData = (try? encoder.encode(newValue)) ?? Data()
        }
    }
}



