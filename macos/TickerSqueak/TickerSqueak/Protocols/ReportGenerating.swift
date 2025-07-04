protocol ReportGenerating {
    /// Asynchronously generates a self-contained, Markdown-formatted string from a checklist template and its state.
    func generateMarkdownReport(for checklist: Checklist, withState state: [String: ChecklistItemState]) async -> String
}
