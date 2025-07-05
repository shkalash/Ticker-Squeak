//
//  ChecklistTemplateProviding.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


/// Defines an interface for loading checklist templates.
protocol ChecklistTemplateProviding {
    /// Asynchronously loads and decodes a checklist template from a given file name (e.g., "pre-market-checklist").
    /// - Parameter name: The base name of the JSON file without the extension.
    /// - Returns: A `Checklist` object representing the template.
    /// - Throws: An error if the file is not found or cannot be decoded.
    func loadJSONTemplate<T>(forName name: String) async throws -> T where T: Decodable
}
