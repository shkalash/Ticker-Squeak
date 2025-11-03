//
//  StandardIgnoreManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation
import Combine
import SwiftData

// MARK: - Ignore List Manager

class StandardIgnoreManager: IgnoreManaging {
    
    
    /// A publisher that emits the updated ignore list whenever a change occurs.
    var ignoreList: AnyPublisher<[String], Never> {
        $internalIgnoreList.eraseToAnyPublisher()
    }
    
    @Published private var internalIgnoreList: [String] = []
    
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // On init, load the ignore list from SwiftData or start with an empty list.
        loadFromSwiftData()
        
        // Automatically save the list back to SwiftData whenever it changes.
        $internalIgnoreList
            .dropFirst() // Don't save during initial load
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // Prevent rapid saves
            .sink { [weak self] updatedList in
                self?.saveToSwiftData(updatedList)
            }
            .store(in: &cancellables)
    }
    
    private func loadFromSwiftData() {
        let descriptor = FetchDescriptor<IgnoredTickerModel>()
        do {
            let models = try modelContext.fetch(descriptor)
            self.internalIgnoreList = models.map { $0.ticker }
        } catch {
            print("[StandardIgnoreManager] Error loading from SwiftData: \(error)")
            self.internalIgnoreList = []
        }
    }
    
    private func saveToSwiftData(_ tickers: [String]) {
        // Fetch current models
        let descriptor = FetchDescriptor<IgnoredTickerModel>()
        guard let currentModels = try? modelContext.fetch(descriptor) else {
            return
        }
        
        let currentTickerSet = Set(tickers)
        let currentModelTickers = Set(currentModels.map { $0.ticker })
        
        // Remove models that are no longer in the list
        for model in currentModels where !currentTickerSet.contains(model.ticker) {
            modelContext.delete(model)
        }
        
        // Add new models
        for ticker in tickers where !currentModelTickers.contains(ticker) {
            let model = IgnoredTickerModel(ticker: ticker)
            modelContext.insert(model)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("[StandardIgnoreManager] Error saving to SwiftData: \(error)")
        }
    }

    func isIgnored(ticker: String) -> Bool {
        internalIgnoreList.contains(ticker)
    }
    
    func addToIgnoreList(_ ticker: String) {
        if !internalIgnoreList.contains(ticker) {
            internalIgnoreList.append(ticker)
        }
    }

    func removeFromIgnoreList(_ ticker: String) {
        internalIgnoreList.removeAll { $0 == ticker }
    }
    
    func clearIgnoreList() {
        internalIgnoreList.removeAll()
        
        // Delete all from SwiftData
        let descriptor = FetchDescriptor<IgnoredTickerModel>()
        do {
            let allModels = try modelContext.fetch(descriptor)
            for model in allModels {
                modelContext.delete(model)
            }
            try modelContext.save()
        } catch {
            print("[StandardIgnoreManager] Error clearing SwiftData: \(error)")
        }
    }
}
