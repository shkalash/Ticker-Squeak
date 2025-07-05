//
//  StandardIgnoreManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation
import Combine

// MARK: - Ignore List Manager

class StandardIgnoreManager: IgnoreManaging {
    
    
    /// A publisher that emits the updated ignore list whenever a change occurs.
    var ignoreList: AnyPublisher<[String], Never> {
        $internalIgnoreList.eraseToAnyPublisher()
    }
    
    @Published private var internalIgnoreList: [String]
    
    private let persistence: PersistenceHandling
    private var cancellables = Set<AnyCancellable>()

    init(persistence: PersistenceHandling) {
        self.persistence = persistence
        
        // On init, load the ignore list from persistence or start with an empty list.
        self.internalIgnoreList = persistence.load(for: .ignoredTickers) ?? []
        
        // Automatically save the list back to persistence whenever it changes.
        $internalIgnoreList
            .dropFirst() // Don't save during initial load
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // Prevent rapid saves
            .sink { [weak self] updatedList in
                self?.persistence.save(value: updatedList, for: .ignoredTickers)
            }
            .store(in: &cancellables)
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
    }
}
