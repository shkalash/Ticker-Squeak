//
//  MarkdownTradeIdeaReportGenerator.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation
import AppKit

/// A concrete implementation that generates a self-contained Markdown report for a specific Trade Idea.
class MarkdownTradeIdeaReportGenerator: TradeIdeaReportGenerating {
    
    private let imagePersister: ImagePersisting

    init(imagePersister: ImagePersisting) {
        self.imagePersister = imagePersister
    }
    
    func generateReport(for idea: TradeIdea, withTemplate checklist: Checklist) async -> String {
        var report = ""

        // Header with "at-a-glance" info from the TradeIdea
        report += "# \(checklist.title) for \(idea.ticker)\n"
        report += "**Status:** \(idea.status.rawValue.capitalized) | **Direction:** \(idea.direction.rawValue.capitalized)\n"
        report += "**Created:** \(idea.createdAt.formatted(date: .abbreviated, time: .shortened))\n\n"

        // Get the state from the idea object
        let state = idea.checklistState.itemStates

        // Body
        for section in checklist.sections {
            report += "### \(section.title)\n"
            for item in section.items {
                let itemState = state[item.id] ?? ChecklistItemState(id: item.id)
                
                switch item.type {
                case .checkbox(let text):
                    let status = itemState.isChecked ? "[x]" : "[ ]"
                    report += "- \(status) \(text)\n"
                    
                case .textInput(let prompt):
                    report += "**\(prompt)**\n"
                    let notes = itemState.userText.isEmpty ? "_No input._" : itemState.userText
                    report += "> \(notes.replacingOccurrences(of: "\n", with: "\n> "))\n\n"
                    
                case .image(let caption):
                    report += "**\(caption)**\n"
                    if itemState.imageFileNames.isEmpty {
                        report += "_No images attached._\n\n"
                    } else {
                        // Load and embed each image using Base64 encoding.
                        for filename in itemState.imageFileNames {
                            let context = ChecklistContext.tradeIdea(id: idea.id)
                            if let image = await imagePersister.loadImage(withFilename: filename, for: context),
                               let pngData = image.pngData() {
                                let base64String = pngData.base64EncodedString()
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