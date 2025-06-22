//
//  SymbolItem.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/22/25.
//


import Foundation

struct SymbolItem: Identifiable, Codable, Equatable {
    enum Direction: String, Codable {
        case none
        case bullish
        case bearish
    }

    let id = UUID()
    let symbol: String
    let receivedAt: Date
    var isHighlighted: Bool = true
    var direction: Direction = .none
}
