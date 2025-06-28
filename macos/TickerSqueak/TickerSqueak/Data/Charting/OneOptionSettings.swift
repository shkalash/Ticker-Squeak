//
//  OneOptionSettings.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/27/25.
//

import Foundation

enum ChartGroup: String, CaseIterable, Codable {
    case none, blue, green, red, yellow
    var displayName: String { rawValue.capitalized }
    var queryValue: String? { self == .none ? nil : rawValue }
}

enum TimeFrame: String, CaseIterable, Codable {
    case none, M5, M15, M30, H1, H4, D1
    var displayName: String { self == .none ? "Chart" : rawValue }
    var queryValue: String? { self == .none ? nil : rawValue }
    private var sortOrder: Int {
        switch self {
        case .M5: return 0
        case .D1: return 1
        case .M15: return 2
        case .M30: return 3
        case .H1: return 4
        case .H4: return 5
        case .none: return 6
        }
    }
    static var sortedCases: [TimeFrame] { allCases.sorted { $0.sortOrder < $1.sortOrder } }
}

struct OneOptionSettings: Codable, Equatable {
    var isEnabled: Bool
    var chartGroup: ChartGroup
    var timeFrame: TimeFrame

    static let `default` = OneOptionSettings(
        isEnabled: false, chartGroup: .none, timeFrame: .none
    )
}
