//
//  SnoozeManaging.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Combine

protocol SnoozeManaging {
    /// Publishes the set of currently snoozed tickers.
    var snoozedTickers: AnyPublisher<Set<String>, Never> { get }
    
    func setSnooze(for ticker: String , isSnoozed: Bool)
    func isSnoozed(ticker: String) -> Bool
    
    // This can be triggered manually or by its internal timer
    func clearSnoozeList()
}
