//
//  MarkdownReportGenerator.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation
import AppKit

/// A concrete implementation of `ReportGenerating` that creates a self-contained Markdown report.
///
/// Images are Base64-encoded and embedded directly into the report, making it portable.
class MarkdownReportGenerator: ReportGenerating {
    
    private let imagePersister: TradeIdeaImagePersisting
    
    // The generator now needs the image persister to load image data.
    init(imagePersister: TradeIdeaImagePersisting) {
        self.imagePersister = imagePersister
    }

    func generateMarkdownReport(for checklist: Checklist, withState state: [String : ChecklistItemState]) async -> String {
        var report = ""

        // Header
        report += "# \(checklist.title)\n"
        let formattedDate = Date().formatted(date: .long, time: .shortened)
        report += "**Date:** \(formattedDate)\n\n"

        // Body
        for section in checklist.sections {
            report += "### \(section.title)\n"
            for item in section.items {
                // Get the state for this specific item, or use a default if not found.
                let itemState = state[item.id] ?? ChecklistItemState(id: item.id)
                
                switch item.type {
                case .checkbox(let text):
                    let status = itemState.isChecked ? "[x]" : "[ ]"
                    report += "- \(status) \(text)\n"
                    
                case .textInput(let prompt):
                    report += "**\(prompt)**\n"
                    let notes = itemState.userText.isEmpty ? "_No input._" : itemState.userText
                    // Using a blockquote for notes
                    report += "> \(notes.replacingOccurrences(of: "\n", with: "\n> "))\n\n"
                    
                case .image(let caption):
                    report += "**\(caption)**\n"
                    if itemState.imageFileNames.isEmpty {
                        report += "_No images attached._\n\n"
                    } else {
                        // Load and embed each image
                        for filename in itemState.imageFileNames {
                            if let image = await imagePersister.loadImage(withFilename: filename),
                               let pngData = image.pngData() {
                                let base64String = pngData.base64EncodedString()
                                // Embed the image using Base64 data URI
                                report += "![Screenshot](data:image/png;base64,\(base64String))\n"
                            }
                        }
                        report += "\n"
                    }
                }
            }
            report += "\n"
        }
        return report
    }
}
