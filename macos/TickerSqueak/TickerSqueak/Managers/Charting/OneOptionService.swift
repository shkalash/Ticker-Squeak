//
//  OneOptionService.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/27/25.
//

import Foundation
import AppKit

/// Handles the logic for opening a ticker in the OneOption app.
class OneOptionService: ChartingService {
    let provider: ChartingProvider = .oneOption
    private let settingsManager: SettingsManaging
    
    init(settingsManager: SettingsManaging) {
        self.settingsManager = settingsManager
    }

    func open(ticker: String) {
        // Only proceed if this service is enabled in the user's settings.
        guard settingsManager.currentSettings.charting.oneOption.isEnabled else { return }
        
        var components = URLComponents()
        components.scheme = "oneoption"
        components.host = "open"
        components.path = "/chart"
        
        var queryItems = [URLQueryItem]()
        
        // Always include the ticker.
        queryItems.append(URLQueryItem(name: "symbol", value: ticker.uppercased()))

        // Conditionally add the timeframe if it's not .none.
        if let tfValue = settingsManager.currentSettings.charting.oneOption.timeFrame.queryValue {
            queryItems.append(URLQueryItem(name: "tf", value: tfValue))
        }

        // Conditionally add the group if it's not .none.
        if let groupValue = settingsManager.currentSettings.charting.oneOption.chartGroup.queryValue {
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

