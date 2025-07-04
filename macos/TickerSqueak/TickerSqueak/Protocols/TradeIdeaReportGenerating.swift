//
//  TradeIdeaReportGenerating.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


/// Defines a contract for generating a report specifically for a Trade Idea.
protocol TradeIdeaReportGenerating {
    /// Asynchronously generates a self-contained Markdown report for a specific Trade Idea.
    func generateReport(for idea: TradeIdea, withTemplate checklist: Checklist) async -> String
}