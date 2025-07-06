//
//  FileBasedPreMarketLogManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/6/25.
//


// FileBasedPreMarketLogManager.swift (New File)
import Foundation

@MainActor
class FileBasedPreMarketLogManager: PreMarketLogManaging {
    private let fileLocationProvider: FileLocationProviding
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let dateFormatter = DateFormatter()

    init(fileLocationProvider: FileLocationProviding, fileManager: FileManager = .default) {
        self.fileLocationProvider = fileLocationProvider
        self.fileManager = fileManager
        self.dateFormatter.dateFormat = "yyyy-MM-dd" // For filenames
    }

    func saveLog(_ state: ChecklistState) async {
        do {
            let directoryURL = try fileLocationProvider.getPreMarketLogDirectory(forMonth: state.lastModified)
            let filename = dateFormatter.string(from: state.lastModified) + ".json"
            let fileURL = directoryURL.appendingPathComponent(filename)
            let data = try encoder.encode(state)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            ErrorManager.shared.report(error)
        }
    }

    func loadLog(for date: Date) async -> ChecklistState? {
        do {
            let directoryURL = try fileLocationProvider.getPreMarketLogDirectory(forMonth: date)
            let filename = dateFormatter.string(from: date) + ".json"
            let fileURL = directoryURL.appendingPathComponent(filename)
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(ChecklistState.self, from: data)
        } catch {
            // It's not an error if a file doesn't exist for a given day.
            return nil
        }
    }
    
    func fetchDatesWithEntries(forMonth month: Date) async -> Set<Date> {
        do {
            let directoryURL = try fileLocationProvider.getPreMarketLogDirectory(forMonth: month)
            let filenames = try fileManager.contentsOfDirectory(atPath: directoryURL.path)
            
            let dates = filenames.compactMap { filename -> Date? in
                // Remove the .json extension before parsing
                let dateString = filename.replacingOccurrences(of: ".json", with: "")
                return dateFormatter.date(from: dateString)
            }
            return Set(dates)
        } catch {
            return []
        }
    }
}
