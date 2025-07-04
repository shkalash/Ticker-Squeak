//
//  LocalFileLocationProvider.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation

/// A concrete implementation of `FileLocationProviding` that resolves standard directory locations within the user's local file system.
///
/// This provider uses the app's `bundleIdentifier` to create a unique folder inside the user's `Library/Application Support` directory.
/// It ensures that all required subdirectories (`Checklists`, `Media`, `Logs`) exist, creating them if they don't already exist.
class LocalFileLocationProvider: FileLocationProviding {

    /// Custom errors that this provider can throw.
    enum LocationError: Error, LocalizedError {
        case appSupportDirectoryNotFound
        case bundleIdentifierMissing
        case directoryCreationFailed(Error)

        var errorDescription: String? {
            switch self {
            case .appSupportDirectoryNotFound:
                return "Could not locate the system's Application Support directory."
            case .bundleIdentifierMissing:
                return "Could not determine the app's bundle identifier. The application may be improperly packaged."
            case .directoryCreationFailed(let underlyingError):
                return "Failed to create a required application directory. Reason: \(underlyingError.localizedDescription)"
            }
        }
    }

    // MARK: - Dependencies

    private let fileManager: FileManager
    private let dateFormatter: DateFormatter

    // MARK: - Initialization

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        // Formatter for creating daily folder names like "2025-07-04"
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "MM-dd-yy"
    }

    // MARK: - FileLocationProviding Conformance

    func getChecklistsDirectory() throws -> URL {
        return try getOrCreateAppDirectory(appending: "Checklists")
    }

    func getMediaDirectory() throws -> URL {
        return try getOrCreateAppDirectory(appending: "Media")
    }

    func getPreMarketLogDirectory() throws -> URL {
            // Creates and returns ".../Logs/pre-market/"
            return try getOrCreateAppDirectory(appending: "Logs/pre-market")
    }
    
    func getTradesLogDirectory(for date: Date) throws -> URL {
        // 1. Get the name of the daily folder (e.g., "2025-07-04").
        let dailyFolderName = dateFormatter.string(from: date)
        
        // 2. Construct the full path including the daily folder.
        let path = "Logs/trades/\(dailyFolderName)"
        
        // 3. Use the helper to create the entire path if it doesn't exist and return the URL.
        return try getOrCreateAppDirectory(appending: path)
    }

    // MARK: - Private Helper

    /// A generic helper function to find or create a specific subdirectory within the app's main Application Support folder.
    private func getOrCreateAppDirectory(appending pathComponent: String) throws -> URL {
        // --- MODIFIED SECTION ---
        // Wrap the entire logic in a do-catch block to report and re-throw errors.
        do {
            // 1. Find the user's Application Support directory.
            guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw LocationError.appSupportDirectoryNotFound
            }

            // 2. Get the app's unique bundle identifier to create a dedicated folder.
            guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
                throw LocationError.bundleIdentifierMissing
            }

            // 3. Construct the full path for our app's specific subdirectory.
            let appDirectoryURL = appSupportURL.appendingPathComponent(bundleIdentifier)
            let finalDirectoryURL = appDirectoryURL.appendingPathComponent(pathComponent)

            // 4. Check if the directory already exists. If not, create it.
            if !fileManager.fileExists(atPath: finalDirectoryURL.path) {
                // withIntermediateDirectories: true will create the parent directories if they don't exist.
                try fileManager.createDirectory(at: finalDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            return finalDirectoryURL
        } catch {
            // 1. Report the error using the shared ErrorManager.
            ErrorManager.shared.report(error)
            
            // 2. Re-throw the error so the calling service knows the operation failed.
            throw error
        }
        // --- END MODIFIED SECTION ---
    }
}
