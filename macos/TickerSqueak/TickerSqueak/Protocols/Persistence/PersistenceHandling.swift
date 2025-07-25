//
//  PersistenceHandling.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


protocol PersistenceHandling {
    /// For codeable objects
    func saveCodable<T: Codable>(object: T?, for key: PersistenceKey<T>)
    func loadCodable<T: Codable>(for key: PersistenceKey<T>) -> T?

    /// For primitives and arrays
    func save<T>(value: T?, for key: PersistenceKey<T>)
    func load<T>(for key: PersistenceKey<T>) -> T?
    
}
