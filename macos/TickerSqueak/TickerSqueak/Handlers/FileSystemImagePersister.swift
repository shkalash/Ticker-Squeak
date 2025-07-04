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
class FileSystemImagePersister: ImagePersisting {

    enum ImageError: Error, LocalizedError {
        case conversionFailed
        case writeFailed(Error)

        var errorDescription: String? {
            switch self {
            case .conversionFailed:
                return "Failed to convert the image to a PNG data format."
            case .writeFailed(let underlyingError):
                return "Failed to write the image data to disk. Reason: \(underlyingError.localizedDescription)"
            }
        }
    }

    private let fileLocationProvider: FileLocationProviding
    private let fileManager: FileManager

    init(fileLocationProvider: FileLocationProviding, fileManager: FileManager = .default) {
        self.fileLocationProvider = fileLocationProvider
        self.fileManager = fileManager
    }

    // MARK: - ImagePersisting Conformance

    func saveImage(_ image: NSImage) async throws -> String {
        do {
            // 1. Convert the NSImage to PNG data.
            guard let pngData = image.pngData() else {
                throw ImageError.conversionFailed
            }

            // 2. Generate a unique filename.
            let filename = UUID().uuidString + ".png"
            
            // 3. Get the destination URL and write the data.
            let mediaDirectory = try fileLocationProvider.getMediaDirectory()
            let fileURL = mediaDirectory.appendingPathComponent(filename)
            try pngData.write(to: fileURL)
            
            // 4. Return the unique filename, which will be stored as state.
            return filename
        } catch {
            ErrorManager.shared.report(error)
            throw error
        }
    }

    func loadImage(withFilename filename: String) async -> NSImage? {
        do {
            let mediaDirectory = try fileLocationProvider.getMediaDirectory()
            let fileURL = mediaDirectory.appendingPathComponent(filename)
            
            // NSImage(contentsOf:) returns nil if the file doesn't exist or isn't a valid image.
            return NSImage(contentsOf: fileURL)
        } catch {
            ErrorManager.shared.report(error)
            return nil
        }
    }
    
    func deleteImage(withFilename filename: String) async throws {
        do {
            let mediaDirectory = try fileLocationProvider.getMediaDirectory()
            let fileURL = mediaDirectory.appendingPathComponent(filename)
            
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            ErrorManager.shared.report(error)
            throw error
        }
    }
}
