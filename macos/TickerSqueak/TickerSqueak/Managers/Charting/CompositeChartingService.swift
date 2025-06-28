//
//  CompositeChartingService.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/27/25.
//


/// A special service that manages and calls multiple other charting services.
/// The rest of the app will interact with this composite service.
class CompositeChartingService: ChartingService {
    // This service doesn't have a specific provider itself.
    // We can assign a placeholder value or handle it as needed.
    let provider: ChartingProvider = .tradingView // Placeholder
    
    private let services: [ChartingService]

    init(services: [ChartingService]) {
        self.services = services
    }

    /// When open is called on the composite, it calls open on all of its child services.
    func open(ticker: String) {
        services.forEach { $0.open(ticker: ticker) }
    }
}