//
//  TVSettingsData.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/22/25.
//


import Foundation

struct TVSettingsData: Codable, Equatable {
    var useTradingView: Bool
    var changeTab: Bool
    var tabNumber: Int
    var tabModifier: ModifierKey
    var delayBeforeTab: TimeInterval
    var delayBeforeTyping: TimeInterval
    var delayBetweenCharacters: TimeInterval

    static let `default` = TVSettingsData(
        useTradingView: false,
        changeTab: true,
        tabNumber: 3,
        tabModifier: .command,
        delayBeforeTab: 0.5,
        delayBeforeTyping: 0.5,
        delayBetweenCharacters: 0.07
    )
    
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
}
