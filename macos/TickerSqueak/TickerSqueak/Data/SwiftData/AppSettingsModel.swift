//
//  AppSettingsModel.swift
//  TickerSqueak
//
//  Created for SwiftData migration
//

import Foundation
import SwiftData

@Model
final class AppSettingsModel {
    // Ticker Management
    var hidingTimout: TimeInterval
    
    // Snooze Management
    var snoozeClearTime: Date
    var soundLibraryData: Data // Stores SoundLibrary as JSON
    var isMuted: Bool
    
    // Server
    var serverPort: Int
    
    // UI Filters
    var showStarred: Bool
    var showUnread: Bool
    var showBullish: Bool
    var showBearish: Bool
    
    // Notifications
    var toastDuration: Double
    var notificationMethodRawValue: Int // Stores NotificationMethod OptionSet rawValue
    
    var chartingData: Data // Stores ChartingSettings as JSON
    
    // Singleton identifier - always "settings"
    @Attribute(.unique) var id: String
    
    init(settings: AppSettings = AppSettings()) {
        self.hidingTimout = settings.hidingTimout
        self.snoozeClearTime = settings.snoozeClearTime
        self.isMuted = settings.isMuted
        self.serverPort = settings.serverPort
        self.showStarred = settings.showStarred
        self.showUnread = settings.showUnread
        self.showBullish = settings.showBullish
        self.showBearish = settings.showBearish
        self.toastDuration = settings.toastDuration
        self.notificationMethodRawValue = settings.notificationMethod.rawValue
        self.id = "settings"
        
        // Encode nested Codable structs to Data
        let encoder = JSONEncoder()
        self.soundLibraryData = (try? encoder.encode(settings.soundLibrary)) ?? Data()
        self.chartingData = (try? encoder.encode(settings.charting)) ?? Data()
    }
    
    // Computed property for convenience
    var notificationMethod: NotificationMethod {
        get {
            NotificationMethod(rawValue: notificationMethodRawValue)
        }
        set {
            notificationMethodRawValue = newValue.rawValue
        }
    }
    
    var soundLibrary: SoundLibrary {
        get {
            let decoder = JSONDecoder()
            return (try? decoder.decode(SoundLibrary.self, from: soundLibraryData)) ?? SoundLibrary()
        }
        set {
            let encoder = JSONEncoder()
            soundLibraryData = (try? encoder.encode(newValue)) ?? Data()
        }
    }
    
    var charting: ChartingSettings {
        get {
            let decoder = JSONDecoder()
            return (try? decoder.decode(ChartingSettings.self, from: chartingData)) ?? ChartingSettings()
        }
        set {
            let encoder = JSONEncoder()
            chartingData = (try? encoder.encode(newValue)) ?? Data()
        }
    }
    
    // Convert to/from AppSettings struct
    func toAppSettings() -> AppSettings {
        var settings = AppSettings()
        settings.hidingTimout = hidingTimout
        settings.snoozeClearTime = snoozeClearTime
        settings.soundLibrary = soundLibrary
        settings.isMuted = isMuted
        settings.serverPort = serverPort
        settings.showStarred = showStarred
        settings.showUnread = showUnread
        settings.showBullish = showBullish
        settings.showBearish = showBearish
        settings.toastDuration = toastDuration
        settings.notificationMethod = notificationMethod
        settings.charting = charting
        return settings
    }
    
    func update(from settings: AppSettings) {
        self.hidingTimout = settings.hidingTimout
        self.snoozeClearTime = settings.snoozeClearTime
        self.soundLibrary = settings.soundLibrary
        self.isMuted = settings.isMuted
        self.serverPort = settings.serverPort
        self.showStarred = settings.showStarred
        self.showUnread = settings.showUnread
        self.showBullish = settings.showBullish
        self.showBearish = settings.showBearish
        self.toastDuration = settings.toastDuration
        self.notificationMethod = settings.notificationMethod
        self.charting = settings.charting
    }
}



