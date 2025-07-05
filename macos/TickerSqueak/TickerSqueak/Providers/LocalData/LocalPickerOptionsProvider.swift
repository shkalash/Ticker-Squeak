//
//  LocalPickerOptionsProvider.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/5/25.
//


import Foundation

class LocalPickerOptionsProvider: PickerOptionsProviding {
    private var options: [String: [String]] = [:]

    init(fileLocationProvider: FileLocationProviding) {
        // In a real implementation, you would use the fileLocationProvider
        // to find and load "picker_options.json" from the Application Support directory.
        // For simplicity here, we'll load from the app bundle.
        guard let url = Bundle.main.url(forResource: "picker_options", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decodedOptions = try? JSONDecoder().decode([String: [String]].self, from: data)
        else {
            self.options = [:]
            ErrorManager.shared.report(URLError(.fileDoesNotExist)) // Report error if file is missing
            return
        }
        self.options = decodedOptions
    }

    func options(for key: String) -> [String] {
        return options[key] ?? []
    }
}