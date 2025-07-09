import Foundation
import Combine
import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class PreMarketChecklistViewModel: PreMarketChecklistViewModelProtocol{
 
    @Published private(set) var title: String = "Pre-Market"
    @Published private(set) var checklist: Checklist?
    @Published private(set) var isLoading: Bool = false
    @Published var error: Error?
    @Published var itemStates: [String: ChecklistItemState] = [:]
    @Published var expandedSectionIDs: Set<String> = []
    @Published var selectedDate: Date = Date() {
        didSet {
            // When the date changes, reload the checklist content for that day.
            guard !Calendar.current.isDate(oldValue, inSameDayAs: selectedDate) else { return }
            Task { await self.loadChecklist(for: selectedDate) }
        }
    }
    @Published var displayedMonth: Date = Date() {
        didSet {
            guard !Calendar.current.isDate(oldValue, equalTo: displayedMonth, toGranularity: .month) else { return }
            Task { await self.fetchDatesWithEntries(forMonth: displayedMonth) }
        }
    }
    /// The set of dates in the displayed month that have a saved log.
    @Published private(set) var datesWithEntry: Set<Date> = []
    @Published private(set) var refreshUUID: UUID = UUID()
    private let checklistName = "pre-market-checklist"
    private let templateProvider: ChecklistTemplateProviding
    private let preMarketLogManager: any PreMarketLogManaging
    private let imagePersister: ImagePersisting
    private let reportGenerator: PreMarketReportGenerating
    private let fileLocationProvider: FileLocationProviding
    let pickerOptionsProvider: PickerOptionsProviding
    init(dependencies: any AppDependencies) {
        self.templateProvider = dependencies.checklistTemplateProvider
        self.preMarketLogManager = dependencies.preMarketLogManager
        self.imagePersister = dependencies.imagePersister
        self.reportGenerator = dependencies.preMarketReportGenerator
        self.fileLocationProvider = dependencies.fileLocationProvider
        self.pickerOptionsProvider = dependencies.pickerOptionsProvider
    }
    
    func options(for key: String) -> [String] {
        self.pickerOptionsProvider.options(for: key)
    }
    
    func load() async {
        await loadChecklist(for: selectedDate)
        await fetchDatesWithEntries(forMonth: displayedMonth)
    }
    
    /// Loads the checklist state for a specific date from the manager.
    private func loadChecklist(for date: Date) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // The template is loaded once.
            if self.checklist == nil {
                self.checklist = try await templateProvider.loadJSONTemplate(forName: checklistName)
                self.title = self.checklist?.title ?? "Pre-Market Checklist"
            }
            
            if let savedState = await preMarketLogManager.loadLog(for: date) {
                self.itemStates = savedState.itemStates
                self.expandedSectionIDs = savedState.expandedSectionIDs
            } else {
                // If no log exists for the selected date, start with a fresh state.
                self.itemStates = [:]
                // Default to all sections expanded for a fresh list.
                self.expandedSectionIDs = Set(checklist?.sections.map { $0.id } ?? [])
            }
        } catch {
            self.error = error
        }
    }
    
    private func fetchDatesWithEntries(forMonth month: Date) async{
        self.datesWithEntry = await preMarketLogManager.fetchDatesWithEntries(forMonth: month)
    }
    
    private func updateAndSaveState(for itemID: String, with newState: ChecklistItemState) {
        itemStates[itemID] = newState
        saveCurrentState()
    }
    
    private func saveCurrentState() {
        Task {
            let stateToSave = ChecklistState(
                lastModified: self.selectedDate,
                itemStates: self.itemStates,
                expandedSectionIDs: self.expandedSectionIDs
            )
            await preMarketLogManager.saveLog(stateToSave)
            
            // After saving, refresh the marked dates in the calendar.
            await fetchDatesWithEntries(forMonth: self.displayedMonth)
            DispatchQueue.main.async {
                self.refreshUUID = UUID()
            }
        }
    }
    
    func goToToday() {
        guard !Calendar.current.isDateInToday(selectedDate) else { return }
        self.selectedDate = Date()
        self.displayedMonth = Date()
    }
    
    // The binding now calls our new, robust update function.
    func binding(for itemID: String) -> Binding<ChecklistItemState> {
        Binding(
            get: { self.itemStates[itemID] ?? ChecklistItemState(id: itemID) },
            set: { newState in self.updateAndSaveState(for: itemID, with: newState) }
        )
    }

    func savePastedImages(_ images: [NSImage], forItemID itemID: String) async {
        let context = ChecklistContext.preMarket(date: selectedDate)
        
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
        
        Task {
            let context = ChecklistContext.preMarket(date: selectedDate)
            try? await imagePersister.deleteImage(withFilename: filename, for: context)
        }
    }
    
    func generateAndExportReport() async {
        guard let checklist = checklist  else { return }
        let currentState = ChecklistState(lastModified: selectedDate, itemStates: itemStates)
        let reportContent = await reportGenerator.generateReport(for: currentState, withTemplate: checklist)
        
        let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        let filename = "\(checklist.title) - \(dateString).md"

        NSSavePanel.present(withContent: reportContent, suggestedFilename: filename)
    }

    func bindingForSectionExpansion(for sectionID: String) -> Binding<Bool> {
        Binding(
            get: { self.expandedSectionIDs.contains(sectionID) },
            set: { isExpanded in
                if isExpanded { self.expandedSectionIDs.insert(sectionID) }
                else { self.expandedSectionIDs.remove(sectionID) }
                self.saveCurrentState()
            }
        )
    }
    func expandAllSections() {
        // To expand all, we get the IDs of all sections from our loaded checklist
        // and create a Set containing all of them.
        guard let checklist = checklist else { return }
        self.expandedSectionIDs = Set(checklist.sections.map { $0.id })
        self.saveCurrentState()
    }

    func collapseAllSections() {
        // To collapse all, we simply clear the set of expanded section IDs.
        self.expandedSectionIDs.removeAll()
        self.saveCurrentState()
    }
}
