//
//  OneOptionViewModel.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/23/25.
//
import Foundation
import Combine
import AppKit

/// An ObservableObject that manages the state, persistence, and logic for OneOption settings.
class OneOptionViewModel: ObservableObject {

    /// The published settings property. The UI will automatically update when this changes.
    @Published var settings: OneOptionSettings {
        didSet {
            // Automatically save the settings whenever they are modified.
            save()
        }
    }
    
    /// A unique key for storing settings in UserDefaults.
    private static let settingsKey = "OneOptionSettings"

    init() {
        // When the ViewModel is created, it loads the settings from disk.
        self.settings = Self.load()
    }

    // --- Persistence Logic ---

    /// Saves the current settings to UserDefaults by encoding them to JSON data.
    private func save() {
        if let encodedData = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encodedData, forKey: Self.settingsKey)
            print("OneOption settings saved.")
        }
    }

    /// Loads settings from UserDefaults. If no settings are found, it returns the default state.
    private static func load() -> OneOptionSettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let decodedSettings = try? JSONDecoder().decode(OneOptionSettings.self, from: data) else {
            print("No saved settings found. Using default OneOption settings.")
            return .default
        }
        print("Successfully loaded OneOption settings.")
        return decodedSettings
    }

    // --- App Functionality ---

    /// Constructs the correct URL based on current settings and opens it.
    ///
    /// This function checks if automation is enabled and only includes parameters for
    /// timeframe and group if they are not set to `.none`.
    /// - Parameter symbol: The stock symbol to open.
    func openChartInOneOptionApp(symbol: String) {
        guard settings.enableOneOptionAutomation else {
            print("OneOption automation is disabled. Aborting.")
            return
        }

        var components = URLComponents()
        components.scheme = "oneoption"
        components.host = "open"
        components.path = "/chart"
        
        var queryItems = [URLQueryItem]()
        
        // Always include the symbol.
        queryItems.append(URLQueryItem(name: "symbol", value: symbol.uppercased()))

        // Conditionally add the timeframe if it's not .none.
        if let tfValue = settings.timeFrame.queryValue {
            queryItems.append(URLQueryItem(name: "tf", value: tfValue))
        }

        // Conditionally add the group if it's not .none.
        if let groupValue = settings.chartGroup.queryValue {
            queryItems.append(URLQueryItem(name: "group", value: groupValue))
        }
        
        components.queryItems = queryItems

        guard let url = components.url else {
            print("Error: Could not create a valid URL for OneOption.")
            return
        }
        
        print("Opening OneOption URL: \(url.absoluteString)")
        NSWorkspace.shared.open(url)
    }
}
