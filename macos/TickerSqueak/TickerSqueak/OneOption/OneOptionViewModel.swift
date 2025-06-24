//
//  OneOptionViewModel.swift
//  TickerSqueak
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
        }
    }

    /// Loads settings from UserDefaults. If no settings are found, it returns the default state.
    private static func load() -> OneOptionSettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let decodedSettings = try? JSONDecoder().decode(OneOptionSettings.self, from: data) else {
            return .default
        }
        return decodedSettings
    }

    // --- App Functionality ---

    /// Constructs the correct URL based on current settings and opens it.
    ///
    /// This function checks if automation is enabled and only includes parameters for
    /// timeframe and group if they are not set to `.none`.
    /// - Parameter ticker: The stock ticker to open.
    func openChartInOneOptionApp(ticker: String) {
        guard settings.enableOneOptionAutomation else {
            return
        }

        var components = URLComponents()
        components.scheme = "oneoption"
        components.host = "open"
        components.path = "/chart"
        
        var queryItems = [URLQueryItem]()
        
        // Always include the ticker.
        queryItems.append(URLQueryItem(name: "symbol", value: ticker.uppercased()))

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
            ErrorManager.shared.report(AppError.chartUrlError(data: "Could not create a valid URL for $\(ticker)."))
            return
        }
        NSWorkspace.shared.open(url)
    }
}
