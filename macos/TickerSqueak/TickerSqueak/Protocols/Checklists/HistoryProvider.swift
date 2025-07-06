//
//  HistoryProvider.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/6/25.
//


import Foundation

protocol HistoryProvider {
    /// Fetches the set of unique dates within a given month/year that contain an entry.
    func fetchDatesWithEntries(forMonth month: Date) async -> Set<Date>
}
