import Foundation
import Combine
import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class TradeChecklistViewModel: TradeChecklistViewModelProtocol {

    @Published private(set) var title: String
    @Published private(set) var checklist: Checklist?
    @Published var itemStates: [String: ChecklistItemState]
    @Published private(set) var isLoading: Bool = false
    @Published var error: Error?
    @Published var expandedSectionIDs: Set<UUID> = []
    @Published var tradeIdea: TradeIdea

    private let checklistName = "trade-checklist"
    private let tradeIdeaManager: TradeIdeaManaging
    private let templateProvider: ChecklistTemplateProviding
    private let imagePersister: ImagePersisting
    private let reportGenerator: TradeIdeaReportGenerating
    private let chartingService: ChartingService
    private var cancellables = Set<AnyCancellable>()

    init(tradeIdea: TradeIdea, dependencies: any AppDependencies) {
        self.tradeIdea = tradeIdea
        self.title = tradeIdea.ticker
        self.itemStates = tradeIdea.checklistState.itemStates

        self.tradeIdeaManager = dependencies.tradeIdeaManager
        self.templateProvider = dependencies.checklistTemplateProvider
        self.imagePersister = dependencies.imagePersister
        self.reportGenerator = dependencies.tradeIdeaReportGenerator
        self.chartingService = dependencies.chartingService
        
        $itemStates
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.saveChanges() }
            .store(in: &cancellables)
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loadedChecklist = try await templateProvider.loadChecklistTemplate(forName: checklistName)
            self.checklist = loadedChecklist
            self.expandedSectionIDs = Set(loadedChecklist.sections.map { $0.id })
        } catch { self.error = error }
    }

    func updateItemState(itemID: String, newState: ChecklistItemState) {
        itemStates[itemID] = newState
    }
    
    func deletePastedImage(filename: String, forItemID itemID: String) {
        var currentState = binding(for: itemID).wrappedValue
        currentState.imageFileNames.removeAll { $0 == filename }
        updateItemState(itemID: itemID, newState: currentState)
        
        Task {
            let context = ChecklistContext.tradeIdea(id: self.tradeIdea.id)
            try? await imagePersister.deleteImage(withFilename: filename, for: context)
        }
    }
    
    func updateStatus(to newStatus: IdeaStatus) {
        let oldStatus = self.tradeIdea.status
        self.tradeIdea.status = newStatus
        if oldStatus == .idea && (newStatus == .taken || newStatus == .rejected) {
            self.tradeIdea.decisionAt = Date()
        } else if newStatus == .idea {
            self.tradeIdea.decisionAt = nil
        }
        // Trigger the autosave by poking the itemStates publisher.
        self.itemStates = self.itemStates
    }
    
    func openInChartingService() {
        chartingService.open(ticker: self.tradeIdea.ticker)
    }

    func savePastedImages(_ images: [NSImage], forItemID itemID: String) async {
        let context = ChecklistContext.tradeIdea(id: self.tradeIdea.id)
        let newFilenames = await withTaskGroup(of: String?.self) { group in
            var filenames: [String] = []
            for image in images { group.addTask { try? await self.imagePersister.saveImage(image, for: context) } }
            for await filename in group where filename != nil { filenames.append(filename!) }
            return filenames
        }
        guard !newFilenames.isEmpty else { return }
        var currentState = binding(for: itemID).wrappedValue
        currentState.imageFileNames.append(contentsOf: newFilenames)
        updateItemState(itemID: itemID, newState: currentState)
    }

    func generateAndExportReport() async {
        guard let checklist = self.checklist else { return }
        let reportContent = await reportGenerator.generateReport(for: self.tradeIdea, withTemplate: checklist)
        let filename = "\(self.tradeIdea.ticker) - Trade Idea.md"
        NSSavePanel.present(withContent: reportContent, suggestedFilename: filename)
    }
    
    private func saveChanges() {
        self.tradeIdea.checklistState.itemStates = self.itemStates
        self.tradeIdea.checklistState.lastModified = Date()
        Task { await tradeIdeaManager.saveIdea(self.tradeIdea) }
    }
    
    func binding(for itemID: String) -> Binding<ChecklistItemState> {
        Binding(
            get: { self.itemStates[itemID] ?? ChecklistItemState(id: itemID) },
            set: { newState in self.updateItemState(itemID: itemID, newState: newState) }
        )
    }
    
    func bindingForSectionExpansion(for sectionID: UUID) -> Binding<Bool> {
        Binding(
            get: { self.expandedSectionIDs.contains(sectionID) },
            set: { isExpanded in
                if isExpanded { self.expandedSectionIDs.insert(sectionID) }
                else { self.expandedSectionIDs.remove(sectionID) }
            }
        )
    }
}
