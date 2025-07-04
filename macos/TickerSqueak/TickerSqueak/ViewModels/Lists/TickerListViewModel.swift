//
//  TickerListViewModel.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation
import Combine
import SwiftUI

/// The ViewModel for the main TickerListView. It is responsible for sourcing data,
/// applying UI filters, and handling all user interactions for the main list.
@MainActor
class TickerListViewModel: ObservableObject {
    
    // MARK: - Published Properties for the UI
    
    /// The final, filtered list of tickers to be displayed in the UI.
    @Published private(set) var visibleTickers: [TickerItem] = []
    
    /// The set of `TickerItem.ID`s for rows that are currently selected by the user.
    @Published var selection = Set<TickerItem.ID>()
    
    /// The total count of unread ticker items from the unfiltered list.
    @Published private(set) var unreadCount: Int = 0
    
    /// The complete, up-to-date settings object for binding to filter controls.
    @Published private(set) var appSettings: AppSettings = AppSettings()

    // MARK: - Private Properties
    
    private let tickerStore: TickerStoreManaging
    private let settingsManager: SettingsManaging
    private let snoozeManager: SnoozeManaging
    private let ignoreManager: IgnoreManaging
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle
    
    init(dependencies: any AppDependencies) {
        // Assign dependencies
        self.tickerStore = dependencies.tickerStore
        self.settingsManager = dependencies.settingsManager
        self.snoozeManager = dependencies.snoozeManager
        self.ignoreManager = dependencies.ignoreManager
        
        // Pipeline 1: Directly subscribe to the SettingsManager's publisher.
        // This ensures the `appSettings` property, which the UI is bound to,
        // is always the most up-to-date version.
        settingsManager.settingsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$appSettings)
        
        // Filtering logic
        
        // 1. Create a publisher for the filtered items and share it
        let filteredItemsPublisher = tickerStore.allTickers
            .combineLatest($appSettings)
            .map { (alerts, settings) -> [TickerItem] in
                return alerts.filter { item in
                    let anyMarkedFilterActive = settings.showUnread || settings.showStarred
                    let anyDirectionFilterActive = settings.showBullish || settings.showBearish

                    // Condition 1: Check marked status (if any such filter is on)
                    let passesMarkedFilter = !anyMarkedFilterActive ||
                                             (settings.showStarred && item.isStarred) ||
                                             (settings.showUnread && item.isUnread)

                    // Condition 2: Check direction (if any such filter is on)
                    let passesDirectionFilter = !anyDirectionFilterActive ||
                                                (settings.showBullish && item.direction == .bullish) ||
                                                (settings.showBearish && item.direction == .bearish)

                    // An item is visible if it passes both sets of active filters.
                    // If a filter set is inactive, its condition is true.
                    return passesMarkedFilter && passesDirectionFilter
                }
            }
            .share() // Share the results to avoid re-calculating for each subscriber

        // 2. First subscriber: Update the visibleTickers array
        filteredItemsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.visibleTickers, on: self)
            .store(in: &cancellables)

        // 3. Second subscriber: Update the selection set
        filteredItemsPublisher
            // Get just the IDs from the visible items
            .map { Set($0.map(\.id)) }
            // Combine with the latest selection set
            .combineLatest($selection)
            // The core logic: find the intersection
            .map { (visibleIDs, currentSelection) in
                return currentSelection.intersection(visibleIDs)
            }
            // IMPORTANT: Prevent an infinite loop if the selection doesn't change
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.selection, on: self)
            .store(in: &cancellables)
        
        // Pipeline 3: Calculates the unread count from the *unfiltered* list.
        // This remains separate as it's not affected by UI filters.
        tickerStore.allTickers
            .map { $0.filter(\.isUnread).count }
            .receive(on: DispatchQueue.main)
            .assign(to: &$unreadCount)
    }
    

    // MARK: - Public Intents for Single Items
    
    func toggleStarred(id: String) { tickerStore.toggleStarred(id: id) }
    func toggleUnread(id: String) { tickerStore.toggleUnread(id: id) }
    func markAsRead(id: String) { tickerStore.markAsRead(id: id) }
    func hideTicker(id: String) { tickerStore.hideTicker(id: id) }
    
    func snoozeTicker(id: String) {
        // Snoozing adds the ticker to the snooze list until the end of the day.
        snoozeManager.setSnooze(for: id, isSnoozed: true)
    }
    
    func addToIgnoreList(ticker: String) { ignoreManager.addToIgnoreList(ticker) }
    func updateDirection(id: String, direction: TickerItem.Direction) { tickerStore.updateDirection(id: id, direction: direction) }
    
    /// Prepares a ticker item to become a trade idea by starring and marking it unread,
    /// then signals that navigation should occur.
    func createAndOpenTradeIdea(id: String) {
        // Star the item if it isn't already.
        tickerStore.markAsStarred(id: id)
        // Always mark as read
        tickerStore.markAsRead(id: id)
    }

    // MARK: - Public Intents for Toolbar and Global Actions
    
    func setFilter(showStarred: Bool) { settingsManager.modify { $0.showStarred = showStarred } }
    func setFilter(showUnread: Bool) { settingsManager.modify { $0.showUnread = showUnread } }
    func setFilter(showBullish: Bool) { settingsManager.modify { $0.showBullish = showBullish } }
    func setFilter(showBearish: Bool) { settingsManager.modify { $0.showBearish = showBearish } }
    func setMute(_ isMuted: Bool) { settingsManager.modify { $0.isMuted = isMuted } }
    func clearAllTickers() { tickerStore.clearAll() }
    func clearSnoozeList() { snoozeManager.clearSnoozeList() }
    
    // MARK: - Batch Actions for Selected Items
    
    enum BatchAction {
        case toggleRead, toggleStar, hide, snooze, ignore, setBullish, setBearish, setNeutral
    }
    
    /// Performs a batch action on all currently selected ticker items.
    func performActionOnSelection(_ action: BatchAction) {
        let selectedIDs = selection
        guard !selectedIDs.isEmpty else { return }
        
        for id in selectedIDs {
            switch action {
                case .toggleRead:
                    tickerStore.toggleUnread(id: id)
                case .toggleStar:
                    tickerStore.toggleStarred(id: id)
                case .setBullish:
                    self.updateDirection(id: id, direction: .bullish)
                case .setBearish:
                    self.updateDirection(id: id, direction: .bearish)
                case .setNeutral:
                    self.updateDirection(id: id, direction: .none)
                case .hide:
                    tickerStore.hideTicker(id: id)
                    selection.removeAll();
                case .snooze:
                    snoozeTicker(id: id)
                    selection.removeAll();
                case .ignore:
                    addToIgnoreList(ticker: id)
                    selection.removeAll();
            }
        }
    }
}
