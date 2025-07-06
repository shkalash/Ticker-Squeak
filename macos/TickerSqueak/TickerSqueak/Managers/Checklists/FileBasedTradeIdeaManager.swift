//
//  FileBasedTradeIdeaManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation

/// A concrete implementation of `TradeIdeaManaging` that uses the local file system as its backing store.
/// Each `TradeIdea` is saved as a separate JSON file within a dated folder structure.
class FileBasedTradeIdeaManager: TradeIdeaManaging {

    // MARK: - Dependencies
    private let fileLocationProvider: FileLocationProviding
    private let imagePersister: ImagePersisting
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        fileLocationProvider: FileLocationProviding,
        imagePersister: ImagePersisting,
        fileManager: FileManager = .default
    ) {
        self.fileLocationProvider = fileLocationProvider
        self.imagePersister = imagePersister
        self.fileManager = fileManager
        
        // Use a date strategy that works well with JSON
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - TradeIdeaManaging Conformance

    func saveIdea(_ idea: TradeIdea) async {
        do {
            // Get the directory for the specific day the idea was created.
            let directoryURL = try fileLocationProvider.getTradesLogDirectory(for: idea.createdAt)
            let fileURL = directoryURL.appendingPathComponent(idea.id.uuidString).appendingPathExtension("json")
            
            let data = try encoder.encode(idea)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            ErrorManager.shared.report(error)
        }
    }

    func fetchIdeas(for date: Date) async -> [TradeIdea] {
        do {
            let directoryURL = try fileLocationProvider.getTradesLogDirectory(for: date)
            
            // Get the URLs of all files in that day's directory.
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            let jsonFiles = fileURLs.filter { $0.pathExtension == "json" }

            // Use a TaskGroup to load and decode all idea files concurrently.
            let ideas = await withTaskGroup(of: TradeIdea?.self, body: { group in
                var results: [TradeIdea] = []
                for url in jsonFiles {
                    group.addTask {
                        guard let data = try? Data(contentsOf: url) else { return nil }
                        return try? self.decoder.decode(TradeIdea.self, from: data)
                    }
                }
                for await idea in group {
                    if let idea = idea {
                        results.append(idea)
                    }
                }
                return results
            })
            
            // Return the ideas sorted by creation time.
            return ideas.sorted { $0.createdAt < $1.createdAt }
        } catch {
            // If the directory doesn't exist or can't be read, it's not an error,
            // it just means there are no ideas for that day. Return an empty array.
            return []
        }
    }

    func fetchDatesWithIdeas(forMonth month: Date) async -> Set<Date> {
        let calendar = Calendar.current
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "MM-dd-yy" // Must match your folder naming convention

        do {
            // 1. Get the URL for the .../trades/{year}/ directory
            let yearURL = try fileLocationProvider.getTradesLogDirectory(forYear: month)

            // 2. Get the names of all the daily folders inside that year's folder
            let dailyFolderNames = try fileManager.contentsOfDirectory(atPath: yearURL.path)
            
            // 3. Convert folder names back to dates and filter for the correct month
            let datesInMonth = dailyFolderNames.compactMap { folderName -> Date? in
                guard let date = dayFormatter.date(from: folderName) else {
                    return nil
                }
                // Ensure the parsed date belongs to the requested month before including it
                return calendar.isDate(date, equalTo: month, toGranularity: .month) ? date : nil
            }
            
            // 4. Return a Set to ensure all dates are unique
            return Set(datesInMonth)
            
        } catch {
            // If the year directory doesn't exist or we can't read it,
            // it simply means there are no ideas for that month. Return an empty set.
            return []
        }
    }
    
    func deleteIdea(_ ideaToDelete: TradeIdea) async {
        do {
            // 1. Delete the TradeIdea's JSON file.
            let directoryURL = try fileLocationProvider.getTradesLogDirectory(for: ideaToDelete.createdAt)
            let fileURL = directoryURL.appendingPathComponent(ideaToDelete.id.uuidString).appendingPathExtension("json")
            
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            
            // 2. IMPORTANT: Delete the entire media folder associated with this idea.
            try await imagePersister.deleteAllImages(for: .tradeIdea(id: ideaToDelete.id) )
            
        } catch {
            ErrorManager.shared.report(error)
        }
    }

    func findOrCreateIdea(forTicker ticker: String, on date: Date) async -> (idea: TradeIdea, wasCreated: Bool) {
        let ideasForDay = await fetchIdeas(for: date)
        
        if let existingIdea = ideasForDay.first(where: { $0.ticker.uppercased() == ticker.uppercased() }) {
            // An idea was found, so 'wasCreated' is false.
            return (idea: existingIdea, wasCreated: false)
        }
        
        // No idea was found, create a new one.
        let newIdea = TradeIdea(
            id: UUID(),
            ticker: ticker.uppercased(),
            createdAt: Date(),
            direction: .none,
            status: .idea,
            decisionAt: nil,
            checklistState: ChecklistState(lastModified: Date(), itemStates: [:])
        )
        
        await saveIdea(newIdea)
        
        // The new idea was just created, so 'wasCreated' is true.
        return (idea: newIdea, wasCreated: true)
    }
}
