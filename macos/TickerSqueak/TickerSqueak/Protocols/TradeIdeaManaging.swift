//
//  TradeIdeaManaging.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation

/// Defines the contract for a service that manages the creation, persistence, and retrieval of `TradeIdea` objects.
protocol TradeIdeaManaging {

    /// Fetches all saved trade ideas for a specific calendar day.
    func fetchIdeas(for date: Date) async -> [TradeIdea]
    
    /// Saves a `TradeIdea` object. This will either create a new file or overwrite an existing one with the same ID.
    func saveIdea(_ idea: TradeIdea) async
    
    /// Deletes a `TradeIdea` and all its associated media.
    func deleteIdea(_ ideaToDelete: TradeIdea) async
    
    /// The key method for navigation: finds an existing idea for a given ticker and date,
    /// or creates and persists a new one if none is found.
    /// The date check should ignore the time component.
    /// Returns a tuple with the idea and indicating if the idea was newly created.
    func findOrCreateIdea(forTicker ticker: String, on date: Date) async -> (idea: TradeIdea, wasCreated: Bool)
}
