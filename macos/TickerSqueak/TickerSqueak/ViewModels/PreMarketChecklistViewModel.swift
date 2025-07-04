//
//  PreMarketChecklistViewModel.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


// PreMarketChecklistViewModel.swift

import Foundation
import Combine
import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class PreMarketChecklistViewModel: PreMarketChecklistViewModelProtocol {
    
    // MARK: - Published Properties
    @Published private(set) var title: String = "Pre-Market Checklist"
    @Published private(set) var checklist: Checklist?
    @Published var itemStates: [String: ChecklistItemState] = [:]
    @Published private(set) var checklistDate: Date?
    @Published private(set) var isLoading: Bool = false
    @Published var error: Error?
    @Published var expandedSectionIDs: Set<UUID> = []

    // MARK: - Private Dependencies
    private let checklistName = "pre-market-checklist" // The file/key identifier
    private let templateProvider: ChecklistTemplateProviding
    private let stateManager: ChecklistStateManaging
    private let imagePersister: TradeIdeaImagePersisting
    private let reportGenerator: ReportGenerating
    private let fileLocationProvider: FileLocationProviding
    
    // MARK: - Lifecycle
    init(dependencies: any AppDependencies) {
        self.templateProvider = dependencies.checklistTemplateProvider
        self.stateManager = dependencies.checklistStateManager
        self.imagePersister = dependencies.imagePersister
        self.reportGenerator = dependencies.reportGenerator
        self.fileLocationProvider = dependencies.fileLocationProvider
    }
    
    // MARK: - Protocol Conformance (Intents)
    
    func load() async {
        isLoading = true
        defer { isLoading = false } // Ensure isLoading is set to false when the function exits
        
        do {
            // Load template and state concurrently
            async let checklistTemplate = templateProvider.loadChecklistTemplate(forName: checklistName)
            async let savedState = stateManager.loadState(forChecklistName: checklistName)
            
            let loadedChecklist = try await checklistTemplate
            self.checklist = loadedChecklist
            self.title = loadedChecklist.title
            
            if let state = await savedState {
                // If state for a previous day is loaded, use it
                self.itemStates = state.itemStates
                self.checklistDate = state.lastModified
            } else {
                // If no state exists, start a new one for today
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
        Task { // Save in the background
            // Package the date and items into the ChecklistState struct for saving
            let stateToSave = ChecklistState(lastModified: self.checklistDate ?? Date(), itemStates: self.itemStates)
            await stateManager.saveState(stateToSave, forChecklistName: checklistName)
        }
    }

    /// Handles pasting one or more new images, persisting them concurrently, and updating the state.
    func savePastedImages(_ images: [NSImage], forItemID itemID: String) async {
        // Use a TaskGroup to save all new images concurrently for better performance.
        let newFilenames = await withTaskGroup(of: String?.self, body: { group in
            var filenames: [String] = []
            
            for image in images {
                group.addTask {
                    // Call the image persister service. Use try? to return nil on failure
                    // so that one bad image doesn't stop the whole process.
                    try? await self.imagePersister.saveImage(image)
                }
            }
            
            // Collect the results as they complete.
            for await filename in group {
                if let filename = filename {
                    filenames.append(filename)
                }
            }
            
            return filenames
        })
        
        // Ensure we have a valid state to update.
        guard !newFilenames.isEmpty else { return }
        var currentState = self.binding(for: itemID).wrappedValue
        
        // Append the newly saved filenames to the existing array.
        currentState.imageFileNames.append(contentsOf: newFilenames)
        
        // Call our existing update method to save the new state and refresh the UI.
        updateItemState(itemID: itemID, newState: currentState)
    }
    
    func startNewDay() async {
        // 1. Save the current checklist to the internal logs folder.
        await saveLogToDisk()
        
        // 2. Reset the state for a new day.
        self.itemStates = [:]
        self.checklistDate = Date()
        
        // 3. Persist the new empty state.
        let freshState = ChecklistState(lastModified: Date(), itemStates: [:])
        await stateManager.saveState(freshState, forChecklistName: checklistName)
    }
    
    /// Internal helper to save the current report to the designated pre-market logs folder.
    private func saveLogToDisk() async {
        guard let checklist = self.checklist, let date = self.checklistDate else { return }
        
        let reportContent = await reportGenerator.generateMarkdownReport(for: checklist, withState: self.itemStates)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yy" // Use the sortable format for filenames
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
    
    /// Generates a report and presents a native "Save As..." dialog to the user for exporting.
    func generateAndExportReport() async {
        // Ensure we have a checklist loaded to generate a report from.
        guard let checklist = self.checklist else { return }
        
        // 1. Asynchronously generate the report string.
        let reportContent = await reportGenerator.generateMarkdownReport(for: checklist, withState: self.itemStates)
        
        // 2. Present the save panel on the main actor.
        let savePanel = NSSavePanel()
        savePanel.title = "Export Checklist Report"
        savePanel.canCreateDirectories = true
        
        // Suggest a descriptive filename.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yy"
        let dateString = dateFormatter.string(from: Date())
        savePanel.nameFieldStringValue = "\(checklist.title) - \(dateString).md"
        
        // --- FIX ---
        // Manually create a UTType for Markdown files.
        // This initializer is failable, so it returns a UTType?
        let markdownUTType = UTType(filenameExtension: "md", conformingTo: .plainText)
        
        // Use compactMap to safely unwrap the optional UTType into the array.
        savePanel.allowedContentTypes = [markdownUTType].compactMap { $0 }
        // --- END FIX ---
        
        // 3. Run the panel and write the file if the user clicks "Save".
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                do {
                    try reportContent.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    ErrorManager.shared.report(error)
                }
            }
        }
    }
    
    func binding(for itemID: String) -> Binding<ChecklistItemState> {
        return Binding(
            // The GET closure: Provide the current state for this item, or a default empty state if none exists.
            get: {
                // Return existing state or a default value. This prevents crashes from optional unwrapping in the View.
                return self.itemStates[itemID] ?? ChecklistItemState(id: itemID)
            },
            // The SET closure: When the View modifies the state (e.g., checks a box), this is called.
            set: { newState in
                // We call our existing update method to handle the logic.
                self.updateItemState(itemID: itemID, newState: newState)
            }
        )
    }
    
    /// Creates a binding to control the expansion state of a single section.
    func bindingForSectionExpansion(for sectionID: UUID) -> Binding<Bool> {
        Binding(
            get: {
                self.expandedSectionIDs.contains(sectionID)
            },
            set: { isExpanded in
                if isExpanded {
                    self.expandedSectionIDs.insert(sectionID)
                } else {
                    self.expandedSectionIDs.remove(sectionID)
                }
            }
        )
    }
    
}
