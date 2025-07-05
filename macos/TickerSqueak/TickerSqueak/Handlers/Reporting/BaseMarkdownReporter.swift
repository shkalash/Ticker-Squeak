//
//  BaseMarkdownReporter.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/5/25.
//

import Foundation
class BaseMarkdownReporter {
    
    internal let imagePersister: ImagePersisting

    init(imagePersister: ImagePersisting) {
        self.imagePersister = imagePersister
    }
    
    internal func generateItemMarkdown(item: ChecklistItem, context: ChecklistContext , itemState : ChecklistItemState, report: inout String) async {
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
                    if let image = await imagePersister.loadImage(withFilename: filename, for: context),
                       let pngData = image.pngData() {
                        let base64String = pngData.base64EncodedString()
                        report += "![Screenshot](data:image/png;base64,\(base64String))\n"
                    }
                }
                report += "\n"
            }
            case .picker(prompt: let prompt, options: _):
                let selectedOption = itemState.selectedOption
                generateOptionMarkdown(prompt: prompt, option: selectedOption ?? "" , report: &report)
            case .dynamicPicker(prompt: let prompt, optionsKey: _):
                let selectedOption = itemState.selectedOption
                generateOptionMarkdown(prompt: prompt, option: selectedOption ?? "" , report: &report)
        }
    }
    
    internal func generateOptionMarkdown(prompt: String , option:String, report:inout String){
        
    }
    
}
