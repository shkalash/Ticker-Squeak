//
//  NotificationMethod.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation

/// A bitmask option set to define how a user should be notified.
/// This allows for configurations like in-app only, desktop only, both, or neither.
struct NotificationMethod: OptionSet, Codable {
    let rawValue: Int

    // MARK: - Individual Notification Methods

    /// Represents an in-app notification, like a temporary toast message.
    static let app     = NotificationMethod(rawValue: 1 << 0) // 1

    /// Represents a system-level desktop notification.
    static let desktop = NotificationMethod(rawValue: 1 << 1) // 2

    // MARK: - Convenience Combinations

    /// A configuration for enabling all possible notification methods.
    static let all: NotificationMethod = [.app, .desktop]
    
    /// A configuration for disabling all notification methods.
    /// This is an empty set, equivalent to creating `NotificationMethod()`.
    static let none: NotificationMethod = []
    
    // MARK: - Easy Checks
    
    /// A convenient property to check if notifications are completely disabled.
    /// Returns `true` if the set is empty.
    var isNone: Bool {
        return self.isEmpty
    }
    
    /// A convenient property to check if all notification methods are enabled.
    var isAll: Bool {
        return self == .all
    }
    
    // MARK: - UI Presentation
    
    /// Provides a user-friendly string describing the current notification setting.
    var description: String {
        switch self {
        case .all:
            return "All Methods"
        case .app:
            return "In-App Only"
        case .desktop:
            return "Desktop Only"
        case .none:
            return "None"
        default:
            // This case handles any combination not explicitly defined above,
            // which could happen if more options are added in the future.
            return "Custom"
        }
    }
}
