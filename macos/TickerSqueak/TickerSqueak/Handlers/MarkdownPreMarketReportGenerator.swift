//
//  MarkdownPreMarketReportGenerator.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation

/// A concrete implementation that generates a Markdown report for the Pre-Market Checklist.
class MarkdownPreMarketReportGenerator: PreMarketReportGenerating {

    // This class has no dependencies as it only processes text data.
    init() {}

    func generateReport(for state: ChecklistState, withTemplate checklist: Checklist) -> String {
        var report = ""

        // Header
        report += "# \(checklist.title)\n"
        report += "**Date:** \(state.lastModified.formatted(date: .long, time: .omitted))\n\n"

        // Body
        for section in checklist.sections {
            report += "### \(section.title)\n"
            for item in section.items {
                let itemState = state.itemStates[item.id] ?? ChecklistItemState(id: item.id)
                
                switch item.type {
                case .checkbox(let text):
                    let status = itemState.isChecked ? "[x]" : "[ ]"
                    report += "- \(status) \(text)\n"
                    
                case .textInput(let prompt):
                    report += "**\(prompt)**\n"
                    let notes = itemState.userText.isEmpty ? "_No input._" : itemState.userText
                    // Use a blockquote for notes, correctly handling multiple lines.
                    report += "> \(notes.replacingOccurrences(of: "\n", with: "\n> "))\n\n"
                    
                case .image:
                    // Pre-market checklist does not support images, so we can ignore this case.
                    // If it were to support them, this is where the logic would go.
                    break
                }
            }
            report += "\n"
        }
        return report
    }
}