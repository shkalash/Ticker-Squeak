//
//  SnoozeMetadataModel.swift
//  TickerSqueak
//
//  Created for SwiftData migration
//

import Foundation
import SwiftData

@Model
final class SnoozeMetadataModel {
    @Attribute(.unique) var id: String // Singleton identifier
    var lastSnoozeClearDate: Date
    
    init(lastSnoozeClearDate: Date = Date()) {
        self.id = "snoozeMetadata"
        self.lastSnoozeClearDate = lastSnoozeClearDate
    }
}



