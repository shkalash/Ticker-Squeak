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
    @Published var tradeIdea: TradeIdea

    var expandedSectionIDs: Set<String> {
        get {
            tradeIdea.checklistState.expandedSectionIDs
        }
        set {
            tradeIdea.checklistState.expandedSectionIDs = newValue
            saveCurrentState()
        }
    }
    
    private let checklistName = "trade-checklist"
    private let tradeIdeaManager: TradeIdeaManaging
    private let templateProvider: ChecklistTemplateProviding
    private let imagePersister: ImagePersisting
    private let reportGenerator: TradeIdeaReportGenerating
    private let chartingService: ChartingService
    private var cancellables = Set<AnyCancellable>()
    private let pickerOptionsProvider: PickerOptionsProviding
    
    init(tradeIdea: TradeIdea, dependencies: any AppDependencies) {
        self.tradeIdea = tradeIdea
        self.title = tradeIdea.ticker
        self.itemStates = tradeIdea.checklistState.itemStates

        self.tradeIdeaManager = dependencies.tradeIdeaManager
        self.templateProvider = dependencies.checklistTemplateProvider
        self.imagePersister = dependencies.imagePersister
        self.reportGenerator = dependencies.tradeIdeaReportGenerator
        self.chartingService = dependencies.chartingService
        self.pickerOptionsProvider = dependencies.pickerOptionsProvider
    }
    
    func options(for key: String) -> [String] {
        self.pickerOptionsProvider.options(for: key)
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loadedChecklist : Checklist = try await templateProvider.loadJSONTemplate(forName: checklistName)
            self.checklist = loadedChecklist
        } catch { self.error = error }
    }

    private func updateAndSaveChanges(for itemID: String, with newState: ChecklistItemState) {
        // 1. Create a mutable copy.
        var newStates = self.itemStates
        
        // 2. Modify the copy.
        newStates[itemID] = newState
        
        // 3. Assign the new dictionary back to the @Published property to trigger the UI update.
        self.itemStates = newStates
        
        // 4. Update the main tradeIdea object and save it in the background.
        self.tradeIdea.checklistState.itemStates = newStates
        self.tradeIdea.checklistState.lastModified = Date()
        saveCurrentState()
    }
    
    private func saveCurrentState() {
        Task {
            await tradeIdeaManager.saveIdea(self.tradeIdea)
        }
    }
    
    // The binding now calls our new, robust update function.
    func binding(for itemID: String) -> Binding<ChecklistItemState> {
        Binding(
            get: { self.itemStates[itemID] ?? ChecklistItemState(id: itemID) },
            set: { newState in self.updateAndSaveChanges(for: itemID, with: newState) }
        )
    }
    
    func deletePastedImage(filename: String, forItemID itemID: String) {
        var currentState = binding(for: itemID).wrappedValue
        currentState.imageFileNames.removeAll { $0 == filename }
        updateAndSaveChanges(for: itemID, with: currentState)
        
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
        updateAndSaveChanges(for: itemID, with: currentState)
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
    
    func bindingForSectionExpansion(for sectionID: String) -> Binding<Bool> {
        Binding(
            get: { self.expandedSectionIDs.contains(sectionID) },
            set: { isExpanded in
                if isExpanded { self.expandedSectionIDs.insert(sectionID) }
                else { self.expandedSectionIDs.remove(sectionID) }
            }
        )
    }
    
    func expandAllSections() {
        // To expand all, we get the IDs of all sections from our loaded checklist
        // and create a Set containing all of them.
        guard let checklist = checklist else { return }
        self.expandedSectionIDs = Set(checklist.sections.map { $0.id })
    }

    func collapseAllSections() {
        // To collapse all, we simply clear the set of expanded section IDs.
        self.expandedSectionIDs.removeAll()
    }
}
