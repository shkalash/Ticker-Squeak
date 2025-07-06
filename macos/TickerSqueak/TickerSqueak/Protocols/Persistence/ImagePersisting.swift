import AppKit

/// Provides a specific context for checklist-related operations, like saving images.
enum ChecklistContext {
    /// Represents the context of a specific trade idea, identified by its UUID.
    case tradeIdea(id: UUID)
    
    /// Represents the context of the pre-market checklist for a specific date.
    case preMarket(date: Date)
}


protocol ImagePersisting {
    /// Saves an NSImage within a given context and returns a unique filename.
    func saveImage(_ image: NSImage, for context: ChecklistContext) async throws -> String
    
    /// Loads the raw Data of an image from persistent storage.
    func loadImageData(withFilename filename: String, for context: ChecklistContext) async -> Data?
    
    /// Deletes a specific image file from a given context.
    func deleteImage(withFilename filename: String, for context: ChecklistContext) async throws
    
    /// Deletes all media associated with a given context (e.g., an entire idea's folder).
    func deleteAllImages(for context: ChecklistContext) async throws
}
