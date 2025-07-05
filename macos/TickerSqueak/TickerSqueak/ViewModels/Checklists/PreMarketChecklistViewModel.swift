import Foundation
import Combine
import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class PreMarketChecklistViewModel: PreMarketChecklistViewModelProtocol{
    
    @Published private(set) var title: String = "Pre-Market Checklist"
    @Published private(set) var checklist: Checklist?
    @Published private(set) var isLoading: Bool = false
    @Published var error: Error?
    @Published var expandedSectionIDs: Set<UUID> = []
    @Published private(set) var refreshID = UUID()
    @Published var itemStates: [String: ChecklistItemState] = [:]
    @Published private(set) var checklistDate: Date?
    
    private let checklistName = "pre-market-checklist"
    private let templateProvider: ChecklistTemplateProviding
    private let stateManager: ChecklistStateManaging
    private let imagePersister: ImagePersisting
    private let reportGenerator: PreMarketReportGenerating
    private let fileLocationProvider: FileLocationProviding
    let pickerOptionsProvider: PickerOptionsProviding
    init(dependencies: any AppDependencies) {
        self.templateProvider = dependencies.checklistTemplateProvider
        self.stateManager = dependencies.checklistStateManager
        self.imagePersister = dependencies.imagePersister
        self.reportGenerator = dependencies.preMarketReportGenerator
        self.fileLocationProvider = dependencies.fileLocationProvider
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
            self.title = loadedChecklist.title
            
            if let savedState = await stateManager.loadState(forChecklistName: checklistName) {
                self.itemStates = savedState.itemStates
                self.checklistDate = savedState.lastModified
            } else {
                // If not, create a new state and put it in the container.
                self.itemStates = [:]
                self.checklistDate = Date()
            }
            self.expandedSectionIDs = Set(loadedChecklist.sections.map { $0.id })
        } catch {
            self.error = error
        }
    }
    
    private func updateAndSaveState(for itemID: String, with newState: ChecklistItemState) {
        itemStates[itemID] = newState
        
        self.refreshID = UUID()
        Task {
            let stateToSave = ChecklistState(lastModified: self.checklistDate ?? Date(), itemStates: self.itemStates)
            await stateManager.saveState(stateToSave, forChecklistName: checklistName)
        }
    }
    
    // The binding now calls our new, robust update function.
    func binding(for itemID: String) -> Binding<ChecklistItemState> {
        Binding(
            get: { self.itemStates[itemID] ?? ChecklistItemState(id: itemID) },
            set: { newState in self.updateAndSaveState(for: itemID, with: newState) }
        )
    }

    func savePastedImages(_ images: [NSImage], forItemID itemID: String) async {
        guard let date = self.checklistDate else { return }
        let context = ChecklistContext.preMarket(date: date)
        
        let newFilenames = await withTaskGroup(of: String?.self) { group in
            var filenames: [String] = []
            for image in images { group.addTask { try? await self.imagePersister.saveImage(image, for: context) } }
            for await filename in group where filename != nil { filenames.append(filename!) }
            return filenames
        }
        
        guard !newFilenames.isEmpty else { return }
        var currentState = binding(for: itemID).wrappedValue
        currentState.imageFileNames.append(contentsOf: newFilenames)
        updateAndSaveState(for: itemID, with: currentState)
    }
    
    func deletePastedImage(filename: String, forItemID itemID: String) {
        var currentState = binding(for: itemID).wrappedValue
        currentState.imageFileNames.removeAll { $0 == filename }
        updateAndSaveState(for: itemID, with: currentState)
        
        // Add safety check for the date before creating the context
        guard let date = self.checklistDate else { return }
        Task {
            let context = ChecklistContext.preMarket(date: date)
            try? await imagePersister.deleteImage(withFilename: filename, for: context)
        }
    }
    
    func startNewDay() async {
        await saveLogToDisk()
        self.itemStates = [:]
        self.checklistDate = Date()
        let freshState = ChecklistState(lastModified: Date(), itemStates: [:])
        await stateManager.saveState(freshState, forChecklistName: checklistName)
    }
    
    func generateAndExportReport() async {
        guard let checklist = checklist, let date = checklistDate else { return }
        let currentState = ChecklistState(lastModified: date, itemStates: itemStates)
        let reportContent = await reportGenerator.generateReport(for: currentState, withTemplate: checklist)
        
        let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        let filename = "\(checklist.title) - \(dateString).md"

        NSSavePanel.present(withContent: reportContent, suggestedFilename: filename)
    }
    
    private func saveLogToDisk() async {
        guard let checklist = self.checklist, let date = self.checklistDate else { return }
        let currentState = ChecklistState(lastModified: date, itemStates: itemStates)
        let reportContent = await reportGenerator.generateReport(for: currentState, withTemplate: checklist)
        
        let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        let filename = "PreMarket-\(dateString).md"
        
        do {
            let directoryURL = try fileLocationProvider.getPreMarketLogDirectory()
            let fileURL = directoryURL.appendingPathComponent(filename)
            try reportContent.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            ErrorManager.shared.report(error)
        }
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
