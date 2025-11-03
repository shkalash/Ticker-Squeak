//
//  SwiftDataTradeIdeaManager.swift
//  TickerSqueak
//
//  Created for SwiftData migration
//

import Foundation
import SwiftData

/// SwiftData-based implementation of TradeIdeaManaging
@MainActor
class SwiftDataTradeIdeaManager: TradeIdeaManaging {
    private let modelContext: ModelContext
    private let imagePersister: ImagePersisting
    
    init(modelContext: ModelContext, imagePersister: ImagePersisting) {
        self.modelContext = modelContext
        self.imagePersister = imagePersister
    }
    
    func fetchIdeas(for date: Date) async -> [TradeIdea] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<TradeIdeaModel>(
            predicate: #Predicate { idea in
                idea.createdAt >= startOfDay && idea.createdAt < endOfDay
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { $0.toTradeIdea() }
        } catch {
            print("[SwiftDataTradeIdeaManager] Error fetching ideas: \(error)")
            return []
        }
    }
    
    func saveIdea(_ idea: TradeIdea) async {
        let descriptor = FetchDescriptor<TradeIdeaModel>(
            predicate: #Predicate { $0.id == idea.id }
        )
        
        do {
            let models = try modelContext.fetch(descriptor)
            if let existingModel = models.first {
                existingModel.update(from: idea)
            } else {
                let newModel = TradeIdeaModel(idea: idea)
                modelContext.insert(newModel)
            }
            try modelContext.save()
        } catch {
            ErrorManager.shared.report(error)
        }
    }
    
    func fetchDatesWithEntries(forMonth month: Date) async -> Set<Date> {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        let descriptor = FetchDescriptor<TradeIdeaModel>(
            predicate: #Predicate { idea in
                idea.createdAt >= startOfMonth && idea.createdAt < startOfNextMonth
            }
        )
        
        do {
            let models = try modelContext.fetch(descriptor)
            let dates = models.map { calendar.startOfDay(for: $0.createdAt) }
            return Set(dates)
        } catch {
            print("[SwiftDataTradeIdeaManager] Error fetching dates: \(error)")
            return []
        }
    }
    
    func deleteIdea(_ ideaToDelete: TradeIdea) async {
        let descriptor = FetchDescriptor<TradeIdeaModel>(
            predicate: #Predicate { $0.id == ideaToDelete.id }
        )
        
        do {
            let models = try modelContext.fetch(descriptor)
            if let modelToDelete = models.first {
                modelContext.delete(modelToDelete)
                try modelContext.save()
                
                // Delete associated images
                try await imagePersister.deleteAllImages(for: .tradeIdea(id: ideaToDelete.id))
            }
        } catch {
            ErrorManager.shared.report(error)
        }
    }
    
    func findOrCreateIdea(forTicker ticker: String, on date: Date) async -> (idea: TradeIdea, wasCreated: Bool) {
        let ideasForDay = await fetchIdeas(for: date)
        
        if let existingIdea = ideasForDay.first(where: { $0.ticker.uppercased() == ticker.uppercased() }) {
            return (idea: existingIdea, wasCreated: false)
        }
        
        // Create new idea
        let newIdea = TradeIdea(
            id: UUID(),
            ticker: ticker.uppercased(),
            createdAt: Date(),
            direction: .none,
            status: .idea,
            decisionAt: nil,
            checklistState: ChecklistState(lastModified: Date(), itemStates: [:])
        )
        
        await saveIdea(newIdea)
        return (idea: newIdea, wasCreated: true)
    }
}



