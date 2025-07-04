import AppKit
import Foundation
extension NSImage {
    /// Converts the NSImage to PNG data format.
    /// - Returns: The image data as a PNG, or `nil` if conversion fails.
    func pngData() -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}
