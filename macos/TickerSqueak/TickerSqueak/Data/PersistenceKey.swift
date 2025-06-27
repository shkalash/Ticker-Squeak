//
//  PersistenceKey.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Foundation
/// A type-safe key for persistence.
/// The `Value` generic parameter links the key to the type of data it stores,
/// preventing type-mismatch errors at compile time.
struct PersistenceKey<Value> {
    let name: String
}
extension PersistenceKey {
    static var tickerItems: PersistenceKey<[TickerItem]> { .init(name: "SavedTickers") }
    static var ignoredTickers: PersistenceKey<[String]> { .init(name: "IgnoredTickers") }
    static var appSettings: PersistenceKey<AppSettings> { .init(name: "SavedAppSettings") }
    static var lastSnoozeClearDate: PersistenceKey<Date> { .init(name: "LastSnoozeClearDate") }
    static var snoozedTickers:PersistenceKey<[String]> { .init(name: "SnoozedTickers") }
}
