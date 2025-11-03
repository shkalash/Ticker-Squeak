//
//  DefaultTickerStore.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation
import Combine
import SwiftData

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
    
    /// Map of ticker symbols to their SwiftData models for efficient updates
    private var tickerModels: [String: TickerItemModel] = [:]
    
    // MARK: - Dependencies
    
    private let tickerReceiver: TickerProviding
    private let ignoreManager: IgnoreManaging
    private let snoozeManager: SnoozeManaging
    private let settingsManager: SettingsManaging
    private let notificationHandler: NotificationHandling
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()

    init(
        tickerReceiver: TickerProviding,
        ignoreManager: IgnoreManaging,
        snoozeManager: SnoozeManaging,
        settingsManager: SettingsManaging,
        notificationHandler: NotificationHandling,
        modelContext: ModelContext
    ) {
        self.tickerReceiver = tickerReceiver
        self.ignoreManager = ignoreManager
        self.snoozeManager = snoozeManager
        self.settingsManager = settingsManager
        self.notificationHandler = notificationHandler
        self.modelContext = modelContext
        
        // Load initial state from SwiftData
        loadFromSwiftData()
        
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
            
        // 2. Automatically save the ticker list to SwiftData when it changes
        $tickerList
            .dropFirst() // Don't save on initial load
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] listToSave in
                self?.saveToSwiftData(listToSave)
            }
            .store(in: &cancellables)
            
        // 3. Automatically remove items if they are added to the ignore list
        ignoreManager.ignoreList
            .sink { [weak self] ignoredTickers in
                let ignoredSet = Set(ignoredTickers)
                self?.tickerList.removeAll { ignoredSet.contains($0.ticker) }
                self?.receivedTickers = self?.receivedTickers.subtracting(ignoredSet) ?? Set<String>()
                // Remove from SwiftData
                for ticker in ignoredSet {
                    if let model = self?.tickerModels[ticker] {
                        self?.modelContext.delete(model)
                        self?.tickerModels.removeValue(forKey: ticker)
                    }
                }
                try? self?.modelContext.save()
            }
            .store(in: &cancellables)
        
        snoozeManager.snoozedTickers
            .sink{ [weak self] snoozedTickers in
                self?.tickerList.removeAll { snoozedTickers.contains($0.ticker) }
                self?.receivedTickers = self?.receivedTickers.subtracting(snoozedTickers) ?? Set<String>()
            }
            .store(in: &cancellables)
    }
    
    private func loadFromSwiftData() {
        let descriptor = FetchDescriptor<TickerItemModel>(
            sortBy: [SortDescriptor(\.receivedAt, order: .reverse)]
        )
        
        do {
            let models = try modelContext.fetch(descriptor)
            self.tickerList = models.map { $0.toTickerItem() }
            self.receivedTickers = Set(models.map { $0.ticker })
            
            // Build the map for efficient updates
            for model in models {
                self.tickerModels[model.ticker] = model
            }
        } catch {
            print("[TickerManager] Error loading from SwiftData: \(error)")
            self.tickerList = []
            self.receivedTickers = []
        }
    }
    
    private func saveToSwiftData(_ items: [TickerItem]) {
        let currentTickerSet = Set(items.map { $0.ticker })
        
        // Remove models that are no longer in the list
        for (ticker, model) in tickerModels where !currentTickerSet.contains(ticker) {
            modelContext.delete(model)
            tickerModels.removeValue(forKey: ticker)
        }
        
        // Update or create models
        for item in items {
            if let existingModel = tickerModels[item.ticker] {
                // Update existing model
                existingModel.isStarred = item.isStarred
                existingModel.isUnread = item.isUnread
                existingModel.direction = item.direction
                // Note: receivedAt doesn't change after creation
            } else {
                // Create new model
                let model = TickerItemModel.from(item)
                modelContext.insert(model)
                tickerModels[item.ticker] = model
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("[TickerManager] Error saving to SwiftData: \(error)")
        }
    }

    // MARK: - Core Logic
    
    func handle(payload: TickerPayload) {
        let ticker = payload.ticker // Already uppercased by the payload's decoder
        
        // Rule 1: Never show an ignored ticker
        if ignoreManager.isIgnored(ticker: ticker) { return }
        
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
                // Also add to SwiftData immediately
                let model = TickerItemModel.from(newItem)
                modelContext.insert(model)
                tickerModels[ticker] = model
                try? modelContext.save()
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
        
        // Add to SwiftData immediately
        let model = TickerItemModel.from(newItem)
        modelContext.insert(model)
        tickerModels[ticker] = model
        try? modelContext.save()
        
        notificationHandler.showNotification(for: ticker, isHighPriority: payload.isHighPriority)
    }

    // MARK: - List & Item Management (from Protocol)
    
    func removeItem(id: String) {
        if let item = tickerList.first(where: { $0.id == id }),
           let model = tickerModels[item.ticker] {
            modelContext.delete(model)
            tickerModels.removeValue(forKey: item.ticker)
            try? modelContext.save()
        }
        tickerList.removeAll { $0.id == id }
        receivedTickers.remove(id)
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
#if DEBUG
            print("[Store] Ticker \(tickerSymbol) has been fully removed from memory after delay.")
#endif
            
        }
        
        pendingRemovals[tickerSymbol] = workItem
        hiddenList.append(tickerSymbol)
        DispatchQueue.main.asyncAfter(deadline: .now() + removalDelay, execute: workItem)
    }
    
    func revealTicker(_ ticker: String) {
        pendingRemovals[ticker]?.cancel()
        pendingRemovals.removeValue(forKey: ticker)
        receivedTickers.remove(ticker)
        hiddenList.removeAll(){ $0 == ticker   }
    }

    func clearAll() {
        for (_, task) in pendingRemovals { task.cancel() }
        pendingRemovals.removeAll()
        receivedTickers.removeAll()
        tickerList.removeAll()
        
        // Delete all from SwiftData
        let descriptor = FetchDescriptor<TickerItemModel>()
        do {
            let allModels = try modelContext.fetch(descriptor)
            for model in allModels {
                modelContext.delete(model)
            }
            try modelContext.save()
            tickerModels.removeAll()
        } catch {
            print("[TickerManager] Error clearing SwiftData: \(error)")
        }
    }
    
    func markAsRead(id: String) {
        if let index = tickerList.firstIndex(where: { $0.id == id }) {
            tickerList[index].isUnread = false
        }
    }
    
    func markAsStarred(id: String) {
        if let index = tickerList.firstIndex(where: { $0.id == id }) {
            tickerList[index].isStarred = true
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
