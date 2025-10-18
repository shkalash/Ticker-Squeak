//
//  ChartingSettings.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/27/25.
//


struct ChartingSettings: Codable, Equatable {
    
    /// The settings for the TradingView integration.
    /// We initialize this property with its default values to ensure the parent
    /// struct (`ChartingSettings`) remains automatically Codable and Equatable.
    var tradingView = TradingViewSettings.default
    
    /// The settings for the OneOption integration.
    var oneOption = OneOptionSettings.default
    
    /// The settings for the TC2000 Bridge integration.
    var tc2000 = TC2000Settings.default
}
