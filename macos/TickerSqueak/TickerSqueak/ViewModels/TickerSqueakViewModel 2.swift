//
//  TickerSqueakViewModel 2.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//
import Foundation
import Combine

class NewTickerSqueakViewModel: ObservableObject {
    // MARK: - Dependencies (Injected)
//    private let tickerStore: TickerStoreManaging
//    private let settingsManager: SettingsManaging
//    private let snoozeManager: SnoozeManaging
//    private let notificationHandler: NotificationHandling
//    //private let chartingIntegrator: Charting // Example for future use
//
//    // MARK: - Published Properties for the View
//    @Published private(set) var visibleTickers: [TickerItem] = []
//    @Published private(set) var unreadCount: Int = 0
//    @Published var showStarredOnly = false
//    @Published var showBullish = true
//    // ... other filter properties
//
//    private var cancellables = Set<AnyCancellable>()
//
//    init(tickerStore: TickerStoreManaging, settingsManager: SettingsManaging, /*... other services */) {
//        self.tickerStore = tickerStore
//        self.settingsManager = settingsManager
//        // ... assign other services
//
//        // The new ViewModel subscribes to the stores and applies UI logic.
//        tickerStore.allTickers
//            .combineLatest($showStarredOnly, $showBullish /*... other filters */)
//            .map { (alerts, showStarred, showBullish) -> [TickerItem] in
//                // This is now the ViewModel's main job: FILTERING for the view.
//                return alerts.filter { item in
//                    if showStarred && !item.isStarred { return false }
//                    // ... other filter logic
//                    return true
//                }
//            }
//            .assign(to: &$visibleTickers)
//        
//        // Update unread count
//        tickerStore.allTickers
//            .map { $0.filter(\.isUnread).count }
//            .assign(to: &$unreadCount)
//    }

    // MARK: - User Intents (Delegation)
    // The view calls these simple, clear methods.
//    
//    func toggleStarred(ticker : String) {
//        tickerStore.toggleStarred(id: ticker)
//    }
//    
//    func snooze(item: TickerItem) {
//        snoozeManager.snooze(ticker: item.ticker)
//        tickerStore.hideTicker(id: item.id) // The store now handles removing it from the list
//    }
//
//    func addToIgnoreList(_ ticker: String) {
//        settingsManager.addToIgnoreList(ticker)
//    }
}
