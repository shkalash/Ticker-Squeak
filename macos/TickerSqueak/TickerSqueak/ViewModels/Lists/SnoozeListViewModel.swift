//
//  SnoozeListViewModel.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/27/25.
//


import Foundation
import Combine

/// The ViewModel for the SnoozeListView, responsible for the state and actions
/// related to the list of currently snoozed tickers.
@MainActor
class SnoozeListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The sorted list of snoozed tickers to be displayed by the view.
    @Published private(set) var snoozedTickers: [String] = []
    
    // MARK: - Private Properties
    
    private let snoozeManager: SnoozeManaging
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle
    
    init(dependencies: any AppDependencies) {
        self.snoozeManager = dependencies.snoozeManager
        
        // Subscribe to the set of snoozed tickers from the manager.
        snoozeManager.snoozedTickers
            .map { snoozedSet in
                // Convert the Set to a sorted Array for stable list presentation.
                Array(snoozedSet).sorted()
            }
            .assign(to: &$snoozedTickers)
    }
    
    // MARK: - Public Intents
    
    /// Removes a single ticker from the snooze list.
    /// - Parameter ticker: The ticker string to remove.
    func remove(ticker: String) {
        snoozeManager.setSnooze(for: ticker, isSnoozed: false)
    }
    
    /// Clears the entire snooze list. This is typically called automatically
    /// at the end of the day but can be triggered manually.
    func clearAll() {
        snoozeManager.clearSnoozeList()
    }
}
