//
//  HiddenTickersViewModel.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/27/25.
//


import Foundation
import Combine

/// The ViewModel for the HiddenTickersView, responsible for displaying tickers that are
/// temporarily hidden and providing actions to reveal them.
@MainActor
class HiddenTickersViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The sorted list of hidden tickers to be displayed by the view.
    @Published private(set) var hiddenTickers: [String] = []
    
    // MARK: - Private Properties
    
    private let tickerStore: TickerStoreManaging
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle
    
    init(dependencies: any AppDependencies) {
        self.tickerStore = dependencies.tickerStore
        
        // Subscribe to the list of hidden tickers from the store.
        // This assumes TickerStoreManaging has a `hiddenTickers` publisher.
        tickerStore.hiddenTickers
            .map { Array($0).sorted() }
            .assign(to: &$hiddenTickers)
    }
    
    // MARK: - Public Intents
    
    /// Reveals a single hidden ticker, canceling its cooldown.
    /// - Parameter ticker: The ticker string to reveal.
    func reveal(ticker: String) {
        // This assumes TickerStoreManaging has a `revealTicker` method.
        tickerStore.revealTicker(ticker)
    }
    
    /// Clears all hidden tickers, canceling all their cooldowns.
    func clearAll() {
        // This reuses the clearAll method which should also clear pending removals.
        tickerStore.clearAll()
    }
}
