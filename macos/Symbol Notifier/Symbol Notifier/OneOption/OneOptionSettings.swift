//
//  OneOptionSettings.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/23/25.
//
import Foundation

/// Represents the chart group colors for OneOption.
enum ChartGroup: String, CaseIterable, Codable {
    case none
    case blue, green, red, yellow

    /// A user-friendly name for display in the UI.
    var displayName: String {
        return self.rawValue.capitalized
    }

    /// The string value to be used in the URL query. Returns `nil` for `.none`.
    var queryValue: String? {
        return self == .none ? nil : self.rawValue
    }
}

/// Represents the chart timeframes for OneOption.
enum TimeFrame: String, CaseIterable, Codable {
    case none, M5, M15, M30, H1, H4, D1

    /// A user-friendly name for display in the UI.
    var displayName: String {
        return self == .none ? "Chart" : self.rawValue
    }

    /// The string value to be used in the URL query. Returns `nil` for `.none`.
    var queryValue: String? {
        return self == .none ? nil : self.rawValue
    }

    /// A private property to define the custom sort order.
    private var sortOrder: Int {
        switch self {
        case .M5: return 0
        case .D1:   return 1
        case .M15:  return 2
        case .M30:  return 3
        case .H1:   return 4
        case .H4:   return 5
        case .none:   return 6
        }
    }

    /// Provides the cases in the desired custom order for the UI.
    static var sortedCases: [TimeFrame] {
        return TimeFrame.allCases.sorted { $0.sortOrder < $1.sortOrder }
    }
}


struct OneOptionSettings: Codable {
    var enableOneOptionAutomation: Bool
    var chartGroup: ChartGroup
    var timeFrame: TimeFrame

    /// Provides a default state for the settings, used on first launch.
    static var `default`: OneOptionSettings {
        OneOptionSettings(
            enableOneOptionAutomation: false,
            chartGroup: .none,
            timeFrame: .none
        )
    }
}
