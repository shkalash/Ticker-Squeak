//
//  Checklist.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//

import Foundation

// Represents the different kinds of items our checklist can have.
// This enum defines the "template" data for each item type.
enum ChecklistItemType {
    case checkbox(text: String)
    case textInput(prompt: String)
    case image(caption: String)
}


// Represents a single item in the checklist.
// It holds both the template data (`type`) and the user's state (`isChecked`, etc.).
struct ChecklistItem: Identifiable {
    let id: String
    let type: ChecklistItemType
    
    // MARK: - User State Properties
    // These properties are managed by the app and are NOT part of the JSON template.
    // They are populated by the ChecklistStateManaging service.
    var isChecked: Bool = false
    var userText: String = ""
    var imageFileNames: [String] = [] // Supports multiple images
}


// Represents a section within the checklist, like "Market Analysis".
struct ChecklistSection: Identifiable, Codable {
    let id = UUID() // For SwiftUI Identifiable conformance. Not in JSON.
    let title: String
    var items: [ChecklistItem]

    // Custom coding keys to ensure the 'id' property is ignored during JSON decoding/encoding.
    private enum CodingKeys: String, CodingKey {
        case title, items
    }
}


// Represents the entire checklist file.
struct Checklist: Codable {
    let title: String
    var sections: [ChecklistSection]
}


// MARK: - Custom Codable Implementation for ChecklistItem
// This is necessary to handle the different item types based on the "type" field in the JSON.
extension ChecklistItem: Codable {
    
    // Define all possible keys present in the JSON for any item type.
    private enum CodingKeys: String, CodingKey {
        case id, type, text, prompt, caption
    }
    
    // Custom decoder to transform JSON data into our Swift objects.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode the properties common to all types.
        id = try container.decode(String.self, forKey: .id)
        let typeString = try container.decode(String.self, forKey: .type)
        
        // Use the 'typeString' to decide how to decode the rest of the object.
        switch typeString {
        case "checkbox":
            let text = try container.decode(String.self, forKey: .text)
            self.type = .checkbox(text: text)
        case "textInput":
            let prompt = try container.decode(String.self, forKey: .prompt)
            self.type = .textInput(prompt: prompt)
        case "image":
            let caption = try container.decode(String.self, forKey: .caption)
            self.type = .image(caption: caption)
        default:
            // If we encounter an unknown type in the JSON, we throw an error.
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Invalid item type received: \(typeString)"
            )
        }
    }
    
    // Custom encoder to transform our Swift objects back into JSON.
    // NOTE: We only encode the TEMPLATE data, not the user's state.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        
        switch type {
        case .checkbox(let text):
            try container.encode("checkbox", forKey: .type)
            try container.encode(text, forKey: .text)
        case .textInput(let prompt):
            try container.encode("textInput", forKey: .type)
            try container.encode(prompt, forKey: .prompt)
        case .image(let caption):
            try container.encode("image", forKey: .type)
            try container.encode(caption, forKey: .caption)
        }
    }
}
