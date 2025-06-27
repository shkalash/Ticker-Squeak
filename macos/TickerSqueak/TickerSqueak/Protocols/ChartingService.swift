//
//  ChartingService.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation

/// Defines the contract for a service that can open a ticker symbol in an external application.
protocol ChartingService {
    func open(ticker: String)
}


/// A placeholder implementation of the ChartingService used for previews and testing.
class PlaceholderChartingService: ChartingService {
    func open(ticker: String) {
        print("[ChartingService] Would open ticker: \(ticker)")
    }
}
