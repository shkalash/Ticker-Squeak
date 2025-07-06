//
//  PreMarketLogManaging.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/6/25.
//


// PreMarketLogManaging.swift (New File)
import Foundation

@MainActor
protocol PreMarketLogManaging: HistoryProvider {
    /// Saves the pre-market checklist state for its given date.
    func saveLog(_ state: ChecklistState) async

    /// Loads the checklist state for a specific date.
    func loadLog(for date: Date) async -> ChecklistState?
}