//
//  PreMarketReportGenerating.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


/// Defines a contract for generating a report specifically for the Pre-Market Checklist.
protocol PreMarketReportGenerating {
    /// Generates a Markdown report from a pre-market checklist's state and template.
    func generateReport(for state: ChecklistState, withTemplate checklist: Checklist) async -> String
}
