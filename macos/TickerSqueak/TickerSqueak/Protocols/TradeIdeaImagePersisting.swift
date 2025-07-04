import AppKit

protocol TradeIdeaImagePersisting {
    /// Saves an NSImage to a folder specific to a TradeIdea and returns a unique filename.
    func saveImage(_ image: NSImage, forIdeaID ideaID: UUID) async throws -> String
    
    /// Loads an NSImage from a TradeIdea's specific folder using its filename.
    func loadImage(withFilename filename: String, fromIdeaID ideaID: UUID) async -> NSImage?
    
    /// Deletes a specific image file from a TradeIdea's folder.
    func deleteImage(withFilename filename: String, forIdeaID ideaID: UUID) async throws
    
    /// Deletes the entire media folder for a given TradeIdea, removing all its images.
    func deleteAllImages(forIdeaID ideaID: UUID) async throws
}
