//
//  NSSavePanel+Extension.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//

import AppKit
import UniformTypeIdentifiers

extension NSSavePanel {
    /// Presents a configured "Save As..." dialog to the user for saving text content.
    /// - Parameters:
    ///   - content: The `String` content to be written to the file.
    ///   - suggestedFilename: The default filename to show in the dialog (e.g., "MyReport.md").
    static func present(withContent content: String, suggestedFilename: String) {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Report"
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = suggestedFilename
        
        // Define and allow the Markdown file type.
        if let markdownUTType = UTType(filenameExtension: "md", conformingTo: .plainText) {
            savePanel.allowedContentTypes = [markdownUTType]
        }

        // Run the panel and write the file if the user clicks "Save".
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                // Report any errors that occur during the file write.
                ErrorManager.shared.report(error)
            }
        }
    }
}
