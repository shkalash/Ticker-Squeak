//
//  SwiftDataPreMarketLogManager.swift
//  TickerSqueak
//
//  Created for SwiftData migration
//

import Foundation
import SwiftData

/// SwiftData-based implementation of PreMarketLogManaging
@MainActor
class SwiftDataPreMarketLogManager: PreMarketLogManaging {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func saveLog(_ state: ChecklistState) async {
        let normalizedDate = PreMarketLogModel.normalizedDate(state.lastModified)
        
        let descriptor = FetchDescriptor<PreMarketLogModel>(
            predicate: #Predicate { $0.logDate == normalizedDate }
        )
        
        do {
            let models = try modelContext.fetch(descriptor)
            if let existingModel = models.first {
                existingModel.state = state
            } else {
                let newModel = PreMarketLogModel(date: state.lastModified, state: state)
                modelContext.insert(newModel)
            }
            try modelContext.save()
        } catch {
            ErrorManager.shared.report(error)
        }
    }
    
    func loadLog(for date: Date) async -> ChecklistState? {
        let normalizedDate = PreMarketLogModel.normalizedDate(date)
        
        let descriptor = FetchDescriptor<PreMarketLogModel>(
            predicate: #Predicate { $0.logDate == normalizedDate }
        )
        
        do {
            let models = try modelContext.fetch(descriptor)
            return models.first?.state
        } catch {
            print("[SwiftDataPreMarketLogManager] Error loading log: \(error)")
            return nil
        }
    }
    
    func fetchDatesWithEntries(forMonth month: Date) async -> Set<Date> {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        let descriptor = FetchDescriptor<PreMarketLogModel>(
            predicate: #Predicate { log in
                log.logDate >= startOfMonth && log.logDate < startOfNextMonth
            }
        )
        
        do {
            let models = try modelContext.fetch(descriptor)
            return Set(models.map { $0.logDate })
        } catch {
            print("[SwiftDataPreMarketLogManager] Error fetching dates: \(error)")
            return []
        }
    }
}



