//
//  TC2000BridgeService.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 10/18/25.
//

import Foundation
import AppKit

/// Handles the logic for opening a ticker via the Windows TC2000 bridge.
class TC2000BridgeService: ChartingService {
    let provider: ChartingProvider = .tc2000
    private let settingsManager: SettingsManaging

    init(settingsManager: SettingsManaging) {
        self.settingsManager = settingsManager
    }

    func open(ticker: String) {
        let cfg = settingsManager.currentSettings.charting.tc2000
        guard cfg.isEnabled else { return }
        guard !cfg.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let urlString = "http://\(cfg.host):\(cfg.port)/tc2000/open"
        guard let url = URL(string: urlString) else {
            ErrorManager.shared.report(AppError.chartUrlError(data: "Invalid TC2000 bridge URL: \(urlString)"))
            return
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = ["symbol": ticker.uppercased()]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            ErrorManager.shared.report(AppError.unknownError(underlyingError: error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                ErrorManager.shared.report(AppError.networkError(description: "Couldn't reach TC2000 bridge. Verify VM networking, and that the bridge app and TC2000 are running. (\(error.localizedDescription))"), level: .warning)
                return
            }
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                ErrorManager.shared.report(AppError.serverError(code: http.statusCode), level: .warning)
                return
            }
            
            // Successfully opened chart in TC2000, now bring the VM window to front
            self.activateVMWindow(vmAppName: cfg.vmAppName)
        }
        task.resume()
    }
    
    /// Brings the VM application window to the front on macOS.
    private func activateVMWindow(vmAppName: String) {
        guard !vmAppName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        DispatchQueue.main.async {
            let workspace = NSWorkspace.shared
            let runningApps = workspace.runningApplications
            
            // Find the VM app by name
            if let vmApp = runningApps.first(where: { app in
                app.localizedName?.lowercased().contains(vmAppName.lowercased()) ?? false
            }) {
                vmApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            }
        }
    }
}
