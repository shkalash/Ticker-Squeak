//
//  TradingViewSettings.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/27/25.
//

import Foundation
enum ModifierKey: String, Codable, CaseIterable, Identifiable {
    case command, control, option, shift, none
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .command: return "Command (⌘)"
        case .control: return "Control (⌃)"
        case .option: return "Option (⌥)"
        case .shift: return "Shift (⇧)"
        case .none: return "None"
        }
    }
}

struct TradingViewSettings: Codable, Equatable {
    var changeTab: Bool
    var tabNumber: Int
    var tabModifier: ModifierKey
    var delayBeforeTab: TimeInterval
    var delayBeforeTyping: TimeInterval
    var delayBetweenCharacters: TimeInterval
    var isEnabled: Bool
    static let `default` = TradingViewSettings(
        changeTab: true, tabNumber: 3, tabModifier: .command,
        delayBeforeTab: 0.5, delayBeforeTyping: 0.5, delayBetweenCharacters: 0.07, isEnabled: false
    )
}
