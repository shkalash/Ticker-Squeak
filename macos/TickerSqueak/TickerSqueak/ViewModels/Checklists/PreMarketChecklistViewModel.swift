import Foundation
import Combine
import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class PreMarketChecklistViewModel: PreMarketChecklistViewModelProtocol {
    
    @Published private(set) var title: String = "Pre-Market Checklist"
    @Published private(set) var checklist: Checklist?
    @Published var itemStates: [String: ChecklistItemState] = [:]
    @Published private(set) var checklistDate: Date?
    @Published private(set) var isLoading: Bool = false
    @Published var error: Error?
    @Published var expandedSectionIDs: Set<UUID> = []

    private let checklistName = "pre-market-checklist"
    private let templateProvider: ChecklistTemplateProviding
    private let stateManager: ChecklistStateManaging
    private let imagePersister: ImagePersisting
    private let reportGenerator: PreMarketReportGenerating
    private let fileLocationProvider: FileLocationProviding
    
    init(dependencies: any AppDependencies) {
        self.templateProvider = dependencies.checklistTemplateProvider
        self.stateManager = dependencies.checklistStateManager
        self.imagePersister = dependencies.imagePersister
        self.reportGenerator = dependencies.preMarketReportGenerator
        self.fileLocationProvider = dependencies.fileLocationProvider
    }
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loadedChecklist = try await templateProvider.loadChecklistTemplate(forName: checklistName)
            self.checklist = loadedChecklist
            self.title = loadedChecklist.title
            
            if let savedState = await stateManager.loadState(forChecklistName: checklistName) {
                self.itemStates = savedState.itemStates
                self.checklistDate = savedState.lastModified
            } else {
                self.itemStates = [:]
                self.checklistDate = Date()
            }
            self.expandedSectionIDs = Set(loadedChecklist.sections.map { $0.id })
        } catch {
            self.error = error
        }
    }
    
    func updateItemState(itemID: String, newState: ChecklistItemState) {
        itemStates[itemID] = newState
        Task {
            let stateToSave = ChecklistState(lastModified: self.checklistDate ?? Date(), itemStates: self.itemStates)
            await stateManager.saveState(stateToSave, forChecklistName: checklistName)
        }
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
        updateItemState(itemID: itemID, newState: currentState)
    }
    
    func deletePastedImage(filename: String, forItemID itemID: String) {
        var currentState = binding(for: itemID).wrappedValue
        currentState.imageFileNames.removeAll { $0 == filename }
        updateItemState(itemID: itemID, newState: currentState)
        
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
        let reportContent = reportGenerator.generateReport(for: currentState, withTemplate: checklist)
        
        let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        let filename = "\(checklist.title) - \(dateString).md"

        NSSavePanel.present(withContent: reportContent, suggestedFilename: filename)
    }
    
    private func saveLogToDisk() async {
        guard let checklist = self.checklist, let date = self.checklistDate else { return }
        let currentState = ChecklistState(lastModified: date, itemStates: itemStates)
        let reportContent = reportGenerator.generateReport(for: currentState, withTemplate: checklist)
        
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
