//
//  ChartingService.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation

/// The contract for any service that can open a ticker in a charting application.
protocol ChartingService {
    /// The specific provider this service represents.
    var provider: ChartingProvider { get }
    
    /// The action to open a given ticker symbol.
    func open(ticker: String)
}
