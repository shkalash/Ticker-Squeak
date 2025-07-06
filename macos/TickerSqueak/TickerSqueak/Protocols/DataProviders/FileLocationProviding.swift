//
//  FileLocationProviding.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation

/// Defines an interface for providing standard file system locations for the app's data.
protocol FileLocationProviding {
    /// Returns the URL for the directory where checklist templates are stored.
    func getChecklistsDirectory() throws -> URL
    
    /// Returns the URL for the directory where user-pasted media is stored.
    func getMediaDirectory() throws -> URL
    
    /// Returns the URL for the directory where pre-market logs are stored (e.g., `.../Logs/pre-market/`).
    func getPreMarketLogDirectory(forMonth date: Date) throws -> URL
    
    /// Returns the URL for the yearly subdirectory where trade logs
    /// This method is responsible for creating the daily folder if it doesn't exist.
    /// - Parameter year: The year for which to get the trade log directory.
    func getTradesLogDirectory(forYear year:Date) throws -> URL
    
    /// Returns the URL for the daily subdirectory where trade logs for a specific date are stored (e.g., `.../Logs/trades/2025-07-04/`).
    /// This method is responsible for creating the daily folder if it doesn't exist.
    /// - Parameter date: The date for which to get the trade log directory.
    func getTradesLogDirectory(for date: Date) throws -> URL
}
