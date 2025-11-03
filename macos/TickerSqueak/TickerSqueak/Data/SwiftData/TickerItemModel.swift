//
//  TickerItemModel.swift
//  TickerSqueak
//
//  Created for SwiftData migration
//

import Foundation
import SwiftData

@Model
final class TickerItemModel {
    var ticker: String
    var receivedAt: Date
    var isStarred: Bool
    var isUnread: Bool
    var directionRawValue: String // Stores Direction enum as String
    
    init(ticker: String, receivedAt: Date, isStarred: Bool = false, isUnread: Bool = true, direction: TickerItem.Direction = .none) {
        self.ticker = ticker
        self.receivedAt = receivedAt
        self.isStarred = isStarred
        self.isUnread = isUnread
        self.directionRawValue = direction.rawValue
    }
    
    // Computed property for convenience
    var direction: TickerItem.Direction {
        get {
            TickerItem.Direction(rawValue: directionRawValue) ?? .none
        }
        set {
            directionRawValue = newValue.rawValue
        }
    }
    
    // Convert to/from TickerItem struct for compatibility
    func toTickerItem() -> TickerItem {
        TickerItem(
            ticker: ticker,
            receivedAt: receivedAt,
            isStarred: isStarred,
            isUnread: isUnread,
            direction: direction
        )
    }
    
    static func from(_ item: TickerItem) -> TickerItemModel {
        TickerItemModel(
            ticker: item.ticker,
            receivedAt: item.receivedAt,
            isStarred: item.isStarred,
            isUnread: item.isUnread,
            direction: item.direction
        )
    }
}



