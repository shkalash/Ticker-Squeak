//
//  LocalFileLocationProvider.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


// In LocalFileLocationProvider.swift

import Foundation

class LocalFileLocationProvider: FileLocationProviding {

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


    private let fileManager: FileManager
    
    private let yearFormatter: DateFormatter
    private let dayFormatter: DateFormatter

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        
        self.yearFormatter = DateFormatter()
        self.yearFormatter.dateFormat = "yyyy"
        
        self.dayFormatter = DateFormatter()
        self.dayFormatter.dateFormat = "MM-dd-yy"
    }

    func getChecklistsDirectory() throws -> URL {
        return try getOrCreateAppDirectory(appending: "Checklists")
    }

    func getMediaDirectory() throws -> URL {
        return try getOrCreateAppDirectory(appending: "Media")
    }
    
    func getPreMarketLogDirectory() throws -> URL {
        return try getOrCreateAppDirectory(appending: "Logs/pre-market")
    }
    
    func getTradesLogDirectory(forYear year:Date) throws -> URL {
        let yearString = yearFormatter.string(from: year)
        
        // 2. Construct the full nested path.
        let path = "Logs/trades/\(yearString)"
        
        // 3. The helper will create all intermediate directories as needed.
        return try getOrCreateAppDirectory(appending: path)
    }

    func getTradesLogDirectory(for date: Date) throws -> URL {
        // 1. Get the year and day strings from the date.
        let yearString = yearFormatter.string(from: date)
        let dayString = dayFormatter.string(from: date)
        
        // 2. Construct the full nested path.
        let path = "Logs/trades/\(yearString)/\(dayString)"
        
        // 3. The helper will create all intermediate directories as needed.
        return try getOrCreateAppDirectory(appending: path)
    }
    
    // The private helper remains the same and works perfectly for this.
    private func getOrCreateAppDirectory(appending pathComponent: String) throws -> URL {
        do {
            guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw LocationError.appSupportDirectoryNotFound
            }

            guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
                throw LocationError.bundleIdentifierMissing
            }

            let finalDirectoryURL = appSupportURL
                .appendingPathComponent(bundleIdentifier)
                .appendingPathComponent(pathComponent)

            if !fileManager.fileExists(atPath: finalDirectoryURL.path) {
                try fileManager.createDirectory(at: finalDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            return finalDirectoryURL
        } catch {
            ErrorManager.shared.report(error)
            throw error
        }
    }
}
