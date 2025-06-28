//
//  AppSettings.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation
import AppKit

struct AppSettings: Codable, Equatable {
    // Ticker Management
    var hidingTimout: TimeInterval = 60 * 60 // 1 Hour
    
    // Snooze Management
    var snoozeClearTime: Date = AppSettings.defaultSnoozeClearTime()
    var soundLibrary: SoundLibrary = SoundLibrary()
    var isMuted: Bool = false
    
    // Server
    var serverPort: Int = 4111
    
    // UI Filters
    var showStarred: Bool = true
    var showUnread: Bool = true
    var showBullish: Bool = true
    var showBearish: Bool = true
    
    // Notifications
    var toastDuration: Double = 2.0
    var notificationMethod : NotificationMethod = .all
    
    var charting: ChartingSettings = ChartingSettings()

    // Helper for default time
    /// Provides a default Date object representing 6 PM in the New York time zone.
    private static func defaultSnoozeClearTime() -> Date {
        guard let nyTimeZone = TimeZone(identifier: "America/New_York") else {
            // Fallback to local 6 PM if timezone is not found
            return Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        }

        var calendar = Calendar.current
        calendar.timeZone = nyTimeZone
        
        // Build components for 6 PM in the New York timezone for the current date
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 18 // 6 PM
        components.minute = 0
        components.second = 0

        // Create the date from these components.
        return calendar.date(from: components) ?? Date()
    }
    
}
