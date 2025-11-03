//
//  TimerBasedSnoozeManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Combine
import Foundation
import SwiftData


// MARK: - Snooze Manager

class TimerBasedSnoozeManager: SnoozeManaging {
    
    var snoozedTickers: AnyPublisher<Set<String>, Never> {
        $internalSnoozedTickers.eraseToAnyPublisher()
    }
    
    @Published private var internalSnoozedTickers: Set<String> = []
    
    private var snoozeClearTimer: Timer?
    private let modelContext: ModelContext
    private let settingsManager: SettingsManaging
    private var metadataModel: SnoozeMetadataModel?
    private var cancellables = Set<AnyCancellable>()

    init(modelContext: ModelContext, settingsManager: SettingsManaging) {
        self.modelContext = modelContext
        self.settingsManager = settingsManager
        
        // Load the initial snoozed list and metadata
        loadFromSwiftData()
        
        let lastCleared = metadataModel?.lastSnoozeClearDate ?? Date()
        
        // check if right now is past the supposed next clear date , if we have any snoozedTickers
        if !internalSnoozedTickers.isEmpty{
            let calendar = Calendar.current
            let clearTime = settingsManager.currentSettings.snoozeClearTime
            let clearComponents = calendar.dateComponents([.hour, .minute], from: clearTime)
            if let nextClearFromLastCleared = calendar.nextDate(after: lastCleared, matching: clearComponents, matchingPolicy: .nextTime){
                if Date() >= nextClearFromLastCleared {
                    clearSnoozeList()
                    print("[Snooze] Time to clear snoozed tickers - last cleared: \(lastCleared), should have cleared by: \(nextClearFromLastCleared)")
                }
            }
        }
        
        
        // Save the list whenever it changes
        $internalSnoozedTickers
            .dropFirst()
            .sink { [weak self] updatedList in
                self?.saveSnoozedTickersToSwiftData(updatedList)
            }
            .store(in: &cancellables)
            
        // Listen for changes to the snooze clear time in settings
        settingsManager.settingsPublisher
            .map { $0.snoozeClearTime }
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.scheduleNextSnoozeClear()
            }
            .store(in: &cancellables)
    }

    func setSnooze(for ticker: String, isSnoozed: Bool) {
        if (isSnoozed){
            internalSnoozedTickers.insert(ticker)
        } else {
            internalSnoozedTickers.remove(ticker)
        }
    }
    
    func isSnoozed(ticker: String) -> Bool {
        internalSnoozedTickers.contains(ticker)
    }

    private func loadFromSwiftData() {
        // Load snoozed tickers
        let tickerDescriptor = FetchDescriptor<SnoozedTickerModel>()
        do {
            let models = try modelContext.fetch(tickerDescriptor)
            self.internalSnoozedTickers = Set(models.map { $0.ticker })
        } catch {
            print("[TimerBasedSnoozeManager] Error loading snoozed tickers: \(error)")
            self.internalSnoozedTickers = []
        }
        
        // Load metadata
        let metadataDescriptor = FetchDescriptor<SnoozeMetadataModel>(
            predicate: #Predicate { $0.id == "snoozeMetadata" }
        )
        do {
            let models = try modelContext.fetch(metadataDescriptor)
            self.metadataModel = models.first
            if self.metadataModel == nil {
                // Create default metadata
                let defaultMetadata = SnoozeMetadataModel(lastSnoozeClearDate: Date())
                modelContext.insert(defaultMetadata)
                try modelContext.save()
                self.metadataModel = defaultMetadata
            }
        } catch {
            print("[TimerBasedSnoozeManager] Error loading metadata: \(error)")
            let defaultMetadata = SnoozeMetadataModel(lastSnoozeClearDate: Date())
            modelContext.insert(defaultMetadata)
            try? modelContext.save()
            self.metadataModel = defaultMetadata
        }
    }
    
    private func saveSnoozedTickersToSwiftData(_ tickers: Set<String>) {
        let descriptor = FetchDescriptor<SnoozedTickerModel>()
        guard let currentModels = try? modelContext.fetch(descriptor) else {
            return
        }
        
        let currentTickerSet = tickers
        let currentModelTickers = Set(currentModels.map { $0.ticker })
        
        // Remove models that are no longer snoozed
        for model in currentModels where !currentTickerSet.contains(model.ticker) {
            modelContext.delete(model)
        }
        
        // Add new models
        for ticker in tickers where !currentModelTickers.contains(ticker) {
            let model = SnoozedTickerModel(ticker: ticker)
            modelContext.insert(model)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("[TimerBasedSnoozeManager] Error saving snoozed tickers: \(error)")
        }
    }
    
    private func saveLastClearDate(_ date: Date) {
        if let model = metadataModel {
            model.lastSnoozeClearDate = date
        } else {
            let model = SnoozeMetadataModel(lastSnoozeClearDate: date)
            modelContext.insert(model)
            metadataModel = model
        }
        
        do {
            try modelContext.save()
        } catch {
            print("[TimerBasedSnoozeManager] Error saving metadata: \(error)")
        }
    }
    
    @objc func clearSnoozeList() {
#if DEBUG
        print("[Snooze] Snooze list cleared.")
#endif
        internalSnoozedTickers.removeAll()
        
        // Delete all from SwiftData
        let descriptor = FetchDescriptor<SnoozedTickerModel>()
        do {
            let allModels = try modelContext.fetch(descriptor)
            for model in allModels {
                modelContext.delete(model)
            }
            try modelContext.save()
        } catch {
            print("[TimerBasedSnoozeManager] Error clearing snoozed tickers: \(error)")
        }
        
        // Save the clear date to prevent clearing again until the next scheduled time
        saveLastClearDate(Date())
        scheduleNextSnoozeClear()
    }
    
    private func scheduleNextSnoozeClear() {
        snoozeClearTimer?.invalidate()
        let calendar = Calendar.current
        let clearTime = settingsManager.currentSettings.snoozeClearTime
        let clearComponents = calendar.dateComponents([.hour, .minute], from: clearTime)
        
        guard let nextClearDate = calendar.nextDate(after: Date(), matching: clearComponents, matchingPolicy: .nextTime) else {
            return
        }
#if DEBUG
        print("[Snooze] Next snooze clear scheduled for \(nextClearDate.formatted(date: .long, time: .standard))")
#endif
        snoozeClearTimer = Timer.scheduledTimer(
            timeInterval: nextClearDate.timeIntervalSinceNow,
            target: self,
            selector: #selector(clearSnoozeList),
            userInfo: nil,
            repeats: false
        )
    }
    
}
