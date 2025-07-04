import AppKit

protocol ImagePersisting {
    /// Saves an NSImage to persistent storage and returns a unique identifier (filename).
    func saveImage(_ image: NSImage) async throws -> String
    
    /// Loads an NSImage from persistent storage using its filename.
    func loadImage(withFilename filename: String) async -> NSImage?
    
    /// Deletes an image from persistent storage using its filename.
    func deleteImage(withFilename filename: String) async throws
}
