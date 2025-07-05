//
//  MarkdownTradeIdeaReportGenerator.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation
import AppKit

/// A concrete implementation that generates a self-contained Markdown report for a specific Trade Idea.
class MarkdownTradeIdeaReportGenerator: BaseMarkdownReporter , TradeIdeaReportGenerating {
    
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
                let context = ChecklistContext.tradeIdea(id: idea.id)
                await generateItemMarkdown(item: item, context:context , itemState: itemState, report: &report)
            }
            report += "\n"
        }
        return report
    }
    
    
}
