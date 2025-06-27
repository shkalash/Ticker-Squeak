//
//  IgnoreListViewModel.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation
import Combine
import SwiftUI

/// The ViewModel for the IgnoreListView, responsible for managing the state and actions
/// related to the ignore list.
@MainActor
class IgnoreListViewModel: ObservableObject {
    
    // MARK: - Published Properties for the UI
    
    /// The list of tickers to be displayed by the view.
    @Published private(set) var ignoreList: [String] = []
    
    // MARK: - Private Properties
    
    private let ignoreManager: IgnoreManaging
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle
    
    init(dependencies: any AppDependencies) {
        self.ignoreManager = dependencies.ignoreManager
        
        // Subscribe to the ignore list from the manager and update our local copy.
        ignoreManager.ignoreList
            .assign(to: &$ignoreList)
    }
    
    // MARK: - Public Intents
    
    /// Adds a collection of new tickers to the ignore list.
    /// - Parameter tickers: An array of strings representing the tickers to add.
    func add(tickers: [String]) {
        for ticker in tickers {
            ignoreManager.addToIgnoreList(ticker)
        }
    }
    
    /// Removes a single ticker from the ignore list.
    /// - Parameter ticker: The ticker string to remove.
    func remove(ticker: String) {
        ignoreManager.removeFromIgnoreList(ticker)
    }
    
    /// Removes all tickers from the ignore list.
    func clearAll() {
        ignoreManager.clearIgnoreList()
    }
}
// Add a placeholder check to the ViewModel
extension IgnoreListViewModel {
    var isPlaceholder: Bool {
        // A simple check to see if this is a placeholder instance.
        // This could be improved, but works for the preview.
        return self.ignoreManager is PlaceholderIgnoreManager
    }
}
