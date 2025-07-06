import Foundation
import Combine
import SwiftUI

@MainActor
class TradeIdeasListViewModel: ObservableObject , MonthlyHistoryProvider, AsyncLoadedViewModel{
    

    // MARK: - Published Properties
    @Published var ideas: [TradeIdea] = []
    @Published var selectedDate: Date = Date() {
        didSet {
            guard !Calendar.current.isDate(oldValue, inSameDayAs: selectedDate) else { return }
            Task { await self.loadIdeasForSelectedDate() }
        }
    }
    @Published var isLoading: Bool = false
    @Published var navigationRequest: TradeIdea?
    @Published private(set) var datesWithEntry: Set<Date> = []
    @Published var displayedMonth: Date = Date() {
        didSet {
            guard !Calendar.current.isDate(oldValue, equalTo: displayedMonth, toGranularity: .month) else { return }
            Task { await self.fetchDatesForDisplayedMonth() }
        }
    }
    
    // MARK: - Private Dependencies & State
    private let tradeIdeaManager: any TradeIdeaManaging
    private let appCoordinator: any AppNavigationCoordinating
    private var isHandlingNavigationRequest = false

    init(dependencies: any AppDependencies) {
        self.tradeIdeaManager = dependencies.tradeIdeaManager
        self.appCoordinator = dependencies.appCoordinator
    }

    /// The single entry point for the view when it first appears.
    func load() async {
        await loadIdeasForSelectedDate()
        await handleInitialNavigationRequest()
    }

    private func loadIdeasForSelectedDate() async {
        isLoading = true
        self.ideas = await tradeIdeaManager.fetchIdeas(for: selectedDate).sorted { $0.createdAt > $1.createdAt }
        // After loading ideas, also refresh the calendar highlights
        await fetchDatesForDisplayedMonth()
        isLoading = false
    }
    
    private func fetchDatesForDisplayedMonth() async {
        self.datesWithEntry = await tradeIdeaManager.fetchDatesWithEntries(forMonth: displayedMonth)
    }
    
    func goToToday() {
        guard !Calendar.current.isDateInToday(selectedDate) else { return }
        self.selectedDate = Date()
        self.displayedMonth = Date()
    }
    

    /// This method handles the one-time navigation request from another tab.
    private func handleInitialNavigationRequest() async {
        // 1. Use the guard flag to ensure this logic only ever runs once per request.
        guard !isHandlingNavigationRequest, let ticker = appCoordinator.tradeIdeaTickerToNavigate else {
            return
        }
        
        isHandlingNavigationRequest = true
        
        // 2. Find or create the idea. This is now the ONLY place this happens during navigation.
        let result = await tradeIdeaManager.findOrCreateIdea(forTicker: ticker, on: Date())
        
        // 3. If the idea was for today but our list is showing a different day, switch to today.
        if !Calendar.current.isDateInToday(selectedDate) {
            selectedDate = Date()
            // Wait for the reload to finish before navigating.
            await loadIdeasForSelectedDate()
        } else if result.wasCreated {
            // If it was newly created for today, just append it locally to the UI.
            self.ideas.append(result.idea)
            self.ideas.sort { $0.createdAt < $1.createdAt }
        }
        
        // 4. Trigger the navigation in the UI.
        self.navigationRequest = result.idea
        
        // 5. Clear the request from the coordinator so it doesn't fire again.
        self.appCoordinator.clearTradeIdeaNavigationRequest()
        self.isHandlingNavigationRequest = false
    }

    /// This is for creating a new idea from the "+" button within the Trade Ideas tab itself.
    func createAndNavigate(toTicker ticker: String) async {
        let result = await tradeIdeaManager.findOrCreateIdea(forTicker: ticker, on: self.selectedDate)
        if result.wasCreated {
            self.ideas.append(result.idea)
            self.ideas.sort { $0.createdAt < $1.createdAt }
        }
        self.navigationRequest = result.idea
    }
    
    func deleteIdea(id: UUID) {
        guard let ideaToDelete = ideas.first(where: { $0.id == id }) else { return }
        ideas.removeAll { $0.id == id }
        Task { await tradeIdeaManager.deleteIdea(ideaToDelete) }
    }
    
    func updateDirection(for ideaID: UUID, to newDirection: TickerItem.Direction) {
        guard let index = ideas.firstIndex(where: { $0.id == ideaID }) else { return }
        ideas[index].direction = newDirection
        Task { await tradeIdeaManager.saveIdea(ideas[index]) }
    }
    
    func updateStatus(for ideaID: UUID, to newStatus: IdeaStatus) {
        guard let index = ideas.firstIndex(where: { $0.id == ideaID }) else { return }
        let oldStatus = ideas[index].status
        ideas[index].status = newStatus
        if oldStatus == .idea && (newStatus == .taken || newStatus == .rejected) {
            ideas[index].decisionAt = Date()
        } else if newStatus == .idea {
            ideas[index].decisionAt = nil
        }
        Task { await tradeIdeaManager.saveIdea(ideas[index]) }
    }
}
