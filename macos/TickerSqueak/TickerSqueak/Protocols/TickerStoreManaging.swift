//
//  TickerStoreManaging.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Combine
import Foundation

protocol TickerStoreManaging {
    /// Publishes the full, updated list of alerts whenever a change occurs.
    var allTickers: AnyPublisher<[TickerItem], Never> { get }
    var hiddenTickers: AnyPublisher<[String], Never> { get }
    
    /// The primary method to process a new ticker payload. It contains the core business logic.
    func handle(payload: TickerPayload)
    
    // MARK: Item State Modification
    func markAsRead(id: String)
    func toggleUnread(id: String)
    func toggleStarred(id: String)
    func updateDirection(id: String, direction: TickerItem.Direction)
    func markAsStarred(id: String)
    
    // MARK: List Management
    func hideTicker(id: String)
    func clearAll()
    func removeItem(id: String)
    func revealTicker(_ ticker: String)
    
}
