//
//  FileSystemImagePersister.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import AppKit

/// A concrete implementation of `ImagePersisting` that saves and loads images from the local file system.
///
/// Images are saved as PNG files with unique UUID-based names in the app's dedicated Media directory.
import Foundation

class FileSystemImagePersister: ImagePersisting {

    enum ImageError: Error, LocalizedError {
        case conversionFailed
        case directoryCreationFailed(Error)

        var errorDescription: String? {
            switch self {
            case .conversionFailed:
                return "Failed to convert the image to a PNG data format."
            case .directoryCreationFailed(let underlyingError):
                return "Failed to create the media directory for the trade idea. Reason: \(underlyingError.localizedDescription)"
            }
        }
    }

    private let fileLocationProvider: FileLocationProviding
    private let fileManager: FileManager
    // A formatter for creating date-based folder names for the pre-market context
    private let dateFormatter: DateFormatter

    init(fileLocationProvider: FileLocationProviding, fileManager: FileManager = .default) {
        self.fileLocationProvider = fileLocationProvider
        self.fileManager = fileManager
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd"
    }

    // MARK: - ImagePersisting Conformance

    func saveImage(_ image: NSImage, for context: ChecklistContext) async throws -> String {
        do {
            let directoryURL = try getOrCreateDirectory(for: context)
            guard let pngData = image.pngData() else { throw ImageError.conversionFailed }
            
            let filename = UUID().uuidString + ".png"
            let fileURL = directoryURL.appendingPathComponent(filename)
            try pngData.write(to: fileURL)
            
            return filename
        } catch {
            ErrorManager.shared.report(error)
            throw error
        }
    }

    func loadImage(withFilename filename: String, for context: ChecklistContext) async -> NSImage? {
        do {
            let directoryURL = try getOrCreateDirectory(for: context)
            let fileURL = directoryURL.appendingPathComponent(filename)
            return NSImage(contentsOf: fileURL)
        } catch {
            ErrorManager.shared.report(error)
            return nil
        }
    }
    
    func deleteImage(withFilename filename: String, for context: ChecklistContext) async throws {
        do {
            let directoryURL = try getOrCreateDirectory(for: context)
            let fileURL = directoryURL.appendingPathComponent(filename)
            
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            ErrorManager.shared.report(error)
            throw error
        }
    }

    func deleteAllImages(for context: ChecklistContext) async throws {
        do {
            let directoryURL = try getOrCreateDirectory(for: context)
            
            if fileManager.fileExists(atPath: directoryURL.path) {
                try fileManager.removeItem(at: directoryURL)
            }
        } catch {
            ErrorManager.shared.report(error)
            throw error
        }
    }

    // MARK: - Private Helper

    /// This is the core of the new logic. It determines the correct subfolder based on the context.
    private func getOrCreateDirectory(for context: ChecklistContext) throws -> URL {
        let baseMediaDirectory = try fileLocationProvider.getMediaDirectory()
        let finalDirectoryURL: URL
        
        // Switch on the context to build the correct path
        switch context {
        case .tradeIdea(let id):
            // Path: .../Media/{UUID}/
            finalDirectoryURL = baseMediaDirectory.appendingPathComponent(id.uuidString)
        case .preMarket(let date):
            // Path: .../Media/pre-market/2025-07-04/
            let dateString = dateFormatter.string(from: date)
            finalDirectoryURL = baseMediaDirectory.appendingPathComponent("pre-market").appendingPathComponent(dateString)
        }
        
        if !fileManager.fileExists(atPath: finalDirectoryURL.path) {
            try fileManager.createDirectory(at: finalDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return finalDirectoryURL
    }
}
