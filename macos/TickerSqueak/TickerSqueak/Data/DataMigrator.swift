//
//  DataMigrator.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation
import SwiftData

/// A utility to handle one-time data migration from UserDefaults and file-based storage
/// to SwiftData models with CloudKit sync.
struct DataMigrator {

    // MARK: - Migration Flag
    
    /// A key to track whether SwiftData migration has already been completed.
    private static let swiftDataMigrationCompletedKey = "swiftDataMigrationCompleted"

    /// Performs the data migration if it has not already been done.
    /// This migrates all data from UserDefaults and file-based storage to SwiftData.
    /// - Parameters:
    ///   - modelContext: The SwiftData ModelContext to save migrated data to
    ///   - persistenceHandler: The old persistence handler for reading UserDefaults data
    ///   - fileLocationProvider: Provider for file-based TradeIdeas and PreMarketLogs
    @MainActor
    static func migrateToSwiftData(
        modelContext: ModelContext,
        persistenceHandler: PersistenceHandling,
        fileLocationProvider: FileLocationProviding
    ) {
        // 1. Check if the migration has already run. If so, do nothing.
        guard !UserDefaults.standard.bool(forKey: swiftDataMigrationCompletedKey) else {
            print("[DataMigrator] SwiftData migration has already been completed. Skipping.")
            return
        }
        
        print("[DataMigrator] Starting SwiftData migration...")
        
        var didMigrateData = false
        
        // 2. Migrate TickerItems
        if let tickerItems: [TickerItem] = persistenceHandler.loadCodable(for: .tickerItems), !tickerItems.isEmpty {
            print("[DataMigrator] Migrating \(tickerItems.count) ticker items...")
            for item in tickerItems {
                let model = TickerItemModel.from(item)
                modelContext.insert(model)
            }
            didMigrateData = true
        }
        
        // 3. Migrate AppSettings
        if let settings: AppSettings = persistenceHandler.loadCodable(for: .appSettings) {
            print("[DataMigrator] Migrating app settings...")
            let settingsModel = AppSettingsModel(settings: settings)
            modelContext.insert(settingsModel)
            didMigrateData = true
        } else {
            // Create default settings if none exist
            let settingsModel = AppSettingsModel(settings: AppSettings())
            modelContext.insert(settingsModel)
        }
        
        // 4. Migrate IgnoredTickers
        if let ignoredTickers: [String] = persistenceHandler.load(for: .ignoredTickers), !ignoredTickers.isEmpty {
            print("[DataMigrator] Migrating \(ignoredTickers.count) ignored tickers...")
            for ticker in ignoredTickers {
                let model = IgnoredTickerModel(ticker: ticker)
                modelContext.insert(model)
            }
            didMigrateData = true
        }
        
        // 5. Migrate SnoozedTickers
        if let snoozedTickers: [String] = persistenceHandler.load(for: .snoozedTickers), !snoozedTickers.isEmpty {
            print("[DataMigrator] Migrating \(snoozedTickers.count) snoozed tickers...")
            for ticker in snoozedTickers {
                let model = SnoozedTickerModel(ticker: ticker)
                modelContext.insert(model)
            }
            didMigrateData = true
        }
        
        // 6. Migrate LastSnoozeClearDate
        if let lastClearDate: Date = persistenceHandler.load(for: .lastSnoozeClearDate) {
            print("[DataMigrator] Migrating last snooze clear date...")
            let metadata = SnoozeMetadataModel(lastSnoozeClearDate: lastClearDate)
            modelContext.insert(metadata)
            didMigrateData = true
        } else {
            // Create default metadata if none exists
            let metadata = SnoozeMetadataModel(lastSnoozeClearDate: Date())
            modelContext.insert(metadata)
        }
        
        // 7. Migrate ChecklistStates (need to check all possible checklist names)
        // Since we don't know all checklist names, we'll try common ones
        let commonChecklistNames = ["pre-market-checklist", "trade-checklist"]
        for checklistName in commonChecklistNames {
            let key = PersistenceKey<ChecklistState>.checklistState(forName: checklistName)
            if let state: ChecklistState = persistenceHandler.loadCodable(for: key) {
                print("[DataMigrator] Migrating checklist state for '\(checklistName)'...")
                let model = ChecklistStateModel(checklistName: checklistName, state: state)
                modelContext.insert(model)
                didMigrateData = true
            }
        }
        
        // Save changes before async migrations
        do {
            try modelContext.save()
        } catch {
            print("[DataMigrator] Error saving initial migrated data: \(error)")
        }
        
        // 8. Migrate file-based TradeIdeas (async, won't block)
        Task { @MainActor in
            await migrateTradeIdeas(modelContext: modelContext, fileLocationProvider: fileLocationProvider)
        }
        
        // 9. Migrate file-based PreMarketLogs (async, won't block)
        Task { @MainActor in
            await migratePreMarketLogs(modelContext: modelContext, fileLocationProvider: fileLocationProvider)
        }
        
        // Mark the migration as complete (file migrations will continue in background)
        UserDefaults.standard.set(true, forKey: swiftDataMigrationCompletedKey)
        
        if didMigrateData {
            print("[DataMigrator] SwiftData migration successful (file migrations continue in background).")
        } else {
            print("[DataMigrator] No old data found to migrate (file migrations continue in background).")
        }
    }
    
    // MARK: - Private Migration Helpers
    
    @MainActor
    private static func migrateTradeIdeas(
        modelContext: ModelContext,
        fileLocationProvider: FileLocationProviding
    ) async {
        let fileManager = FileManager.default
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "MM-dd-yy"
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        
        do {
            // Get all year directories
            let baseURL = try fileLocationProvider.getTradesLogDirectory(forYear: Date())
            let yearsDir = baseURL.deletingLastPathComponent()
            
            guard fileManager.fileExists(atPath: yearsDir.path) else {
                print("[DataMigrator] No trades log directory found.")
                return
            }
            
            let yearDirs = try fileManager.contentsOfDirectory(at: yearsDir, includingPropertiesForKeys: nil)
            
            var migratedCount = 0
            for yearDir in yearDirs {
                guard let yearString = Int(yearDir.lastPathComponent),
                      let dayDirs = try? fileManager.contentsOfDirectory(at: yearDir, includingPropertiesForKeys: nil) else {
                    continue
                }
                
                for dayDir in dayDirs {
                    guard let jsonFiles = try? fileManager.contentsOfDirectory(at: dayDir, includingPropertiesForKeys: nil)
                        .filter({ $0.pathExtension == "json" }) else {
                        continue
                    }
                    
                    for jsonFile in jsonFiles {
                        guard let data = try? Data(contentsOf: jsonFile),
                              let idea = try? decoder.decode(TradeIdea.self, from: data) else {
                            continue
                        }
                        
                        let model = TradeIdeaModel(idea: idea)
                        modelContext.insert(model)
                        migratedCount += 1
                    }
                }
            }
            
            if migratedCount > 0 {
                print("[DataMigrator] Migrated \(migratedCount) trade ideas from files.")
                try? modelContext.save()
            }
        } catch {
            print("[DataMigrator] Error migrating trade ideas: \(error)")
        }
    }
    
    @MainActor
    private static func migratePreMarketLogs(
        modelContext: ModelContext,
        fileLocationProvider: FileLocationProviding
    ) async {
        let fileManager = FileManager.default
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        do {
            // Try to find pre-market logs for the last 2 years
            let calendar = Calendar.current
            let now = Date()
            
            for yearOffset in 0...1 {
                guard let yearDate = calendar.date(byAdding: .year, value: -yearOffset, to: now) else {
                    continue
                }
                
                for month in 1...12 {
                    guard let monthDate = calendar.date(bySetting: .month, value: month, of: yearDate) else {
                        continue
                    }
                    
                    guard let directoryURL = try? fileLocationProvider.getPreMarketLogDirectory(forMonth: monthDate),
                          fileManager.fileExists(atPath: directoryURL.path),
                          let jsonFiles = try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
                        .filter({ $0.pathExtension == "json" }) else {
                        continue
                    }
                    
                    for jsonFile in jsonFiles {
                        let filename = jsonFile.deletingPathExtension().lastPathComponent
                        guard let date = dateFormatter.date(from: filename),
                              let data = try? Data(contentsOf: jsonFile),
                              let state = try? decoder.decode(ChecklistState.self, from: data) else {
                            continue
                        }
                        
                        let model = PreMarketLogModel(date: date, state: state)
                        modelContext.insert(model)
                    }
                }
            }
            
            try? modelContext.save()
            print("[DataMigrator] Pre-market logs migration completed.")
        } catch {
            print("[DataMigrator] Error migrating pre-market logs: \(error)")
        }
    }
}
