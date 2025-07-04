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
class FileSystemImagePersister: TradeIdeaImagePersisting {

    /// Custom errors specific to image persistence operations.
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

        // MARK: - Dependencies
        private let fileLocationProvider: FileLocationProviding
        private let fileManager: FileManager

        // MARK: - Initialization
        init(fileLocationProvider: FileLocationProviding, fileManager: FileManager = .default) {
            self.fileLocationProvider = fileLocationProvider
            self.fileManager = fileManager
        }

        // MARK: - ImagePersisting Conformance

        func saveImage(_ image: NSImage, forIdeaID ideaID: UUID) async throws -> String {
            do {
                // 1. Get the destination directory specific to this Trade Idea.
                let ideaMediaDirectory = try getOrCreateMediaDirectory(forIdeaID: ideaID)

                // 2. Convert the NSImage to PNG data using our extension.
                guard let pngData = image.pngData() else {
                    throw ImageError.conversionFailed
                }

                // 3. Generate a unique filename for the image itself.
                let filename = UUID().uuidString + ".png"
                let fileURL = ideaMediaDirectory.appendingPathComponent(filename)

                // 4. Write the data to disk.
                try pngData.write(to: fileURL)
                
                // 5. Return the unique filename, which will be stored in the TradeIdea's state.
                return filename
            } catch {
                ErrorManager.shared.report(error)
                throw error
            }
        }

        func loadImage(withFilename filename: String, fromIdeaID ideaID: UUID) async -> NSImage? {
            do {
                let ideaMediaDirectory = try getOrCreateMediaDirectory(forIdeaID: ideaID)
                let fileURL = ideaMediaDirectory.appendingPathComponent(filename)
                
                // NSImage(contentsOf:) gracefully returns nil if the file doesn't exist.
                return NSImage(contentsOf: fileURL)
            } catch {
                ErrorManager.shared.report(error)
                return nil
            }
        }
        
        func deleteImage(withFilename filename: String, forIdeaID ideaID: UUID) async throws {
            do {
                let ideaMediaDirectory = try getOrCreateMediaDirectory(forIdeaID: ideaID)
                let fileURL = ideaMediaDirectory.appendingPathComponent(filename)
                
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                }
            } catch {
                ErrorManager.shared.report(error)
                throw error
            }
        }

        func deleteAllImages(forIdeaID ideaID: UUID) async throws {
            do {
                // Get the URL for the entire idea-specific folder and remove it.
                let ideaMediaDirectory = try getOrCreateMediaDirectory(forIdeaID: ideaID)
                
                if fileManager.fileExists(atPath: ideaMediaDirectory.path) {
                    try fileManager.removeItem(at: ideaMediaDirectory)
                }
            } catch {
                ErrorManager.shared.report(error)
                throw error
            }
        }

        // MARK: - Private Helper

        /// Gets the URL for an idea's specific media folder (e.g., .../Media/{UUID}/), creating it if it doesn't exist.
        private func getOrCreateMediaDirectory(forIdeaID ideaID: UUID) throws -> URL {
            let baseMediaDirectory = try fileLocationProvider.getMediaDirectory()
            let ideaMediaURL = baseMediaDirectory.appendingPathComponent(ideaID.uuidString)
            
            if !fileManager.fileExists(atPath: ideaMediaURL.path) {
                try fileManager.createDirectory(at: ideaMediaURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            return ideaMediaURL
        }
}
