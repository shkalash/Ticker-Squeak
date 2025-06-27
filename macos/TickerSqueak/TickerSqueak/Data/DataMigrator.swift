//
//  DataMigrator.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation

/// A utility to handle one-time data migration from the old UserDefaults format
/// to the new structured settings managed by our services.
struct DataMigrator {

    // MARK: - Old UserDefaults Keys
    // These keys are from the original TickerSqueakViewModel.
    private static let oldIgnoreListKey = "SavedIgnoreList"
    // Add other old keys here as needed, e.g.:
    // private static let oldAlertSoundKey = "alertSound"
    // private static let oldServerPortKey = "ServerPort"

    // MARK: - Migration Flag
    
    /// A key to track whether this V2 migration has already been completed.
    private static let migrationCompletedKey = "migrationToV2ArchitectureCompleted"

    /// Performs the data migration if it has not already been done.
    /// This should be called once at app startup from the DependencyContainer.
    /// - Parameters:
    ///   - settingsManager: The app's settings manager to save migrated settings to.
    ///   - ignoreManager: The app's ignore manager to save the ignore list to.
    static func migrate(settingsManager: SettingsManaging, ignoreManager: IgnoreManaging) {
        // 1. Check if the migration has already run. If so, do nothing.
        guard !UserDefaults.standard.bool(forKey: migrationCompletedKey) else {
            print("[DataMigrator] Migration has already been completed. Skipping.")
            return
        }
        
        print("[DataMigrator] Starting one-time data migration...")
        
        var didMigrateData = false

        // 2. Migrate the Ignore List
        if let oldIgnoreList = UserDefaults.standard.array(forKey: oldIgnoreListKey) as? [String] {
            if !oldIgnoreList.isEmpty {
                print("[DataMigrator] Migrating \(oldIgnoreList.count) items from old ignore list...")
                oldIgnoreList.forEach { ignoreManager.addToIgnoreList($0) }
                didMigrateData = true
            }
        }
        
        // 3. Migrate other individual settings into the AppSettings object
        // Example: Migrating the server port
        // let oldPort = UserDefaults.standard.integer(forKey: oldServerPortKey)
        // if oldPort > 0 {
        //     settingsManager.modify { $0.serverPort = oldPort }
        //     didMigrateData = true
        // }
        
        // Example: Migrating sound settings
        // if let oldSound = UserDefaults.standard.string(forKey: oldAlertSoundKey) {
        //     settingsManager.modify { $0.soundLibrary.setSound(for: .alert, to: oldSound) }
        //     didMigrateData = true
        // }
        
        // Add other migration tasks here...

        // 4. Mark the migration as complete so it never runs again.
        UserDefaults.standard.set(true, forKey: migrationCompletedKey)
        
        if didMigrateData {
            print("[DataMigrator] Migration successful.")
        } else {
            print("[DataMigrator] No old data found to migrate.")
        }
    }
}
