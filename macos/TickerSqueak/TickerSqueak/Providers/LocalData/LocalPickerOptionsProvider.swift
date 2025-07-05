//
//  LocalPickerOptionsProvider.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/5/25.
//


import Foundation

class LocalPickerOptionsProvider: PickerOptionsProviding {
    
    typealias optionsDictionary = [String: [String]]
    private var options: optionsDictionary = [:]

    private let templatePrivder: ChecklistTemplateProviding

    init(templatePrivder: ChecklistTemplateProviding) {
        self.templatePrivder = templatePrivder
        Task{
            do{
                self.options = try await templatePrivder.loadJSONTemplate(forName: "picker-options")
            }
            catch {
                self.options = [:]
            }
        }
    }

    func options(for key: String) -> [String] {
        return options[key] ?? []
    }
}
