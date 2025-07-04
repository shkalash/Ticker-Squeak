//
//  TradeIdeasListViewModel.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation
import Combine
import SwiftUI

@MainActor
class TradeIdeasListViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var ideas: [TradeIdea] = []
    @Published var selectedDate: Date = Date()
    @Published var isLoading: Bool = false
    
    /// When the View sees this property change to a non-nil value, it should trigger programmatic navigation.
    @Published var navigationRequest: TradeIdea?

    // MARK: - Private Dependencies
    private let tradeIdeaManager: TradeIdeaManaging
    private var cancellables = Set<AnyCancellable>()

    init(dependencies: any AppDependencies) {
        self.tradeIdeaManager = dependencies.tradeIdeaManager // We will add this to the container next

        // When the selectedDate changes, automatically reload the ideas for that day.
        $selectedDate
            .removeDuplicates() // Only fire when the day actually changes
            .sink { [weak self] _ in
                Task {
                    await self?.loadIdeas()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Intents

    /// Fetches all trade ideas for the currently selected date.
    func loadIdeas() async {
        isLoading = true
        // Fetch ideas from the manager service.
        let fetchedIdeas = await tradeIdeaManager.fetchIdeas(for: selectedDate)
        self.ideas = fetchedIdeas
        self.isLoading = false
    }

    /// Deletes one or more ideas from the list based on the user's selection in the UI.
    func deleteIdeas(at offsets: IndexSet) {
        let ideasToDelete = offsets.map { self.ideas[$0] }
        
        Task {
            // Concurrently delete all selected items.
            await withTaskGroup(of: Void.self) { group in
                for idea in ideasToDelete {
                    group.addTask {
                        await self.tradeIdeaManager.deleteIdea(idea)
                    }
                }
            }
            // Refresh the list from the source of truth after deletion.
            await loadIdeas()
        }
    }

    /// Handles an external request to navigate to a specific ticker.
    /// It finds or creates the idea, then sets the navigationRequest to trigger the UI.
    func handleNavigationRequest(forTicker ticker: String) async {
        let idea = await tradeIdeaManager.findOrCreateIdea(forTicker: ticker, on: Date())
        
        // If the date is not today, switch to today first.
        if !Calendar.current.isDateInToday(self.selectedDate) {
            self.selectedDate = Date()
        }
        
        self.navigationRequest = idea
    }
}