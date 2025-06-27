//
//  DefaultTickerStore.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation
import Combine

class TickerManager: TickerStoreManaging {
    
    
    
    
    
    // MARK: - Public Properties (from Protocol)
    
    var allTickers: AnyPublisher<[TickerItem], Never> {
        $tickerList.eraseToAnyPublisher()
    }
    
    var hiddenTickers: AnyPublisher<[String], Never> {
        $hiddenList.eraseToAnyPublisher()
    }
    
    // MARK: - Private State
    
    @Published private var tickerList: [TickerItem] = []
    @Published private var hiddenList: [String] = []
    /// A set of all tickers we've seen in the current session, used to manage hide/re-appear logic.
    private var receivedTickers: Set<String> = []
    
    /// A dictionary to hold cancellation tasks for tickers that have been temporarily hidden.
    private var pendingRemovals: [String: DispatchWorkItem] = [:]
    
    /// A local copy of the ignore list, kept in sync with the IgnoreManager.
    private var currentIgnoreList: [String] = []
    
    // MARK: - Dependencies
    
    private let tickerReceiver: TickerProviding
    private let ignoreManager: IgnoreManaging
    private let snoozeManager: SnoozeManaging
    private let settingsManager: SettingsManaging
    private let notificationHandler: NotificationHandling
    private let persistence: PersistenceHandling
    private var cancellables = Set<AnyCancellable>()

    init(
        tickerReceiver: TickerProviding,
        ignoreManager: IgnoreManaging,
        snoozeManager: SnoozeManaging,
        settingsManager: SettingsManaging,
        notificationHandler: NotificationHandling,
        persistence: PersistenceHandling
    ) {
        self.tickerReceiver = tickerReceiver
        self.ignoreManager = ignoreManager
        self.snoozeManager = snoozeManager
        self.settingsManager = settingsManager
        self.notificationHandler = notificationHandler
        self.persistence = persistence
        
        // Load initial state from persistence
        loadFromPersistence()
        
        // Setup subscriptions to automatically handle events
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // 1. Listen for new ticker payloads from the server
        tickerReceiver.payloadPublisher
            .sink { [weak self] payload in
                self?.handle(payload: payload)
            }
            .store(in: &cancellables)
            
        // 2. Automatically save the ticker list to persistence when it changes
        $tickerList
            .dropFirst() // Don't save on initial load
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] listToSave in
                self?.persistence.save(object: listToSave, for: .tickerItems)
            }
            .store(in: &cancellables)
            
        // 3. Automatically remove items if they are added to the ignore list
        ignoreManager.ignoreList
            .sink { [weak self] ignoredTickers in
                let ignoredSet = Set(ignoredTickers)
                self?.tickerList.removeAll { ignoredSet.contains($0.ticker) }
            }
            .store(in: &cancellables)
    }
    
    private func loadFromPersistence() {
        let loadedTickers: [TickerItem] = persistence.load(for: .tickerItems) ?? []
        self.tickerList = loadedTickers
        self.receivedTickers = Set(loadedTickers.map { $0.ticker })
    }

    // MARK: - Core Logic
    
    func handle(payload: TickerPayload) {
        let ticker = payload.ticker // Already uppercased by the payload's decoder
        
        // Rule 1: Never show an ignored ticker
        if currentIgnoreList.contains(ticker) { return }
        
        // Rule 2: If snoozed, only show if high priority
        if snoozeManager.isSnoozed(ticker: ticker) && !payload.isHighPriority { return }
        
        // Rule 3: If pending removal (recently hidden), do not show
        if pendingRemovals[ticker] != nil { return }
        
        // Logic for an already received ticker
        if receivedTickers.contains(ticker) {
            guard payload.isHighPriority else { return } // Only re-surface for high priority
            
            if let index = tickerList.firstIndex(where: { $0.ticker == ticker }) {
                // Ticker is visible, just mark as unread and move to top
                var item = tickerList.remove(at: index)
                item.isUnread = true
                tickerList.insert(item, at: 0)
            } else {
                // Ticker was hidden, create a new item
                let newItem = TickerItem(ticker: ticker, receivedAt: Date(), isUnread: true)
                tickerList.insert(newItem, at: 0)
            }
            
            // If it was snoozed, this high-priority alert unsnoozes it
            if snoozeManager.isSnoozed(ticker: ticker) {
                snoozeManager.setSnooze(for: ticker , isSnoozed : false)
            }
            
            notificationHandler.showNotification(for: ticker, isHighPriority: true)
            return
        }
        
        // Logic for a brand new ticker
        receivedTickers.insert(ticker)
        let newItem = TickerItem(ticker: ticker, receivedAt: Date())
        tickerList.insert(newItem, at: 0)
        notificationHandler.showNotification(for: ticker, isHighPriority: payload.isHighPriority)
    }

    // MARK: - List & Item Management (from Protocol)
    
    func removeItem(id: String) {
        tickerList.removeAll { $0.id == id }
    }
    
    func hideTicker(id: String) {
        // Find the ticker symbol for the given ID (which is the same string)
        guard let itemToRemove = tickerList.first(where: { $0.id == id }) else { return }
        let tickerSymbol = itemToRemove.ticker
        
        // Remove from the visible list
        tickerList.removeAll { $0.id == id }
        
        // Cancel any previous removal task for this ticker
        pendingRemovals[tickerSymbol]?.cancel()
        
        let removalDelay = settingsManager.currentSettings.hidingTimout
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.receivedTickers.remove(tickerSymbol)
            self.pendingRemovals.removeValue(forKey: tickerSymbol)
            print("[Store] Ticker \(tickerSymbol) has been fully removed from memory after delay.")
        }
        
        pendingRemovals[tickerSymbol] = workItem
        hiddenList.append(tickerSymbol)
        DispatchQueue.main.asyncAfter(deadline: .now() + removalDelay, execute: workItem)
    }
    
    func revealTicker(_ ticker: String) {
        pendingRemovals[ticker]?.cancel()
        pendingRemovals.removeValue(forKey: ticker)
        hiddenList.removeAll(){ $0 == ticker   }
    }

    func clearAll() {
        for (_, task) in pendingRemovals { task.cancel() }
        pendingRemovals.removeAll()
        receivedTickers.removeAll()
        tickerList.removeAll()
    }
    
    func markAsRead(id: String) {
        if let index = tickerList.firstIndex(where: { $0.id == id }) {
            tickerList[index].isUnread = false
        }
    }
    
    func toggleUnread(id: String) {
        if let index = tickerList.firstIndex(where: { $0.id == id }) {
            tickerList[index].isUnread.toggle()
        }
    }

    func toggleStarred(id: String) {
        if let index = tickerList.firstIndex(where: { $0.id == id }) {
            tickerList[index].isStarred.toggle()
        }
    }
    
    func updateDirection(id: String, direction: TickerItem.Direction) {
        if let index = tickerList.firstIndex(where: { $0.id == id }) {
            tickerList[index].direction = direction
        }
    }
}
