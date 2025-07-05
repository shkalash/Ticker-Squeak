//
//  MarkdownPreMarketReportGenerator.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation

/// A concrete implementation that generates a Markdown report for the Pre-Market Checklist.
class MarkdownPreMarketReportGenerator: BaseMarkdownReporter , PreMarketReportGenerating {

    func generateReport(for state: ChecklistState, withTemplate checklist: Checklist) async -> String {
        var report = ""
        
        // Header
        report += "# \(checklist.title)\n"
        report += "**Date:** \(state.lastModified.formatted(date: .long, time: .omitted))\n\n"
        
        // Body
        for section in checklist.sections {
            report += "### \(section.title)\n"
            for item in section.items {
                let itemState = state.itemStates[item.id] ?? ChecklistItemState(id: item.id)
                let context = ChecklistContext.preMarket(date: state.lastModified)
                await generateItemMarkdown(item: item, context:context , itemState: itemState, report: &report)
            }
        }
        report += "\n"
        return report
    }
    
}

