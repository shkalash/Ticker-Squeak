//
//  ServerSettingsViewModel.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation
import Combine

/// The ViewModel for the ServerSettingsView. It manages the state and actions
/// related to the application's local ticker server.
@MainActor
class ServerSettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties for the UI
    
    /// The current running state of the server.
    @Published private(set) var isServerRunning: Bool = false
    
    /// The *actual* port the server is currently configured to use.
    @Published private(set) var currentServerPort: Int = 4111
    
    /// The temporary port value being edited by the user in the TextField.
    @Published var editedPortText: String = "4111"
    
    /// Determines if the "Apply" and "Revert" buttons should be enabled.
    var hasUnappliedChanges: Bool {
        // The button is active if the edited text, when converted to a valid Int,
        // is different from the currently active server port.
        guard let editedPort = Int(editedPortText) else { return false }
        return editedPort != currentServerPort
    }

    // MARK: - Private Properties
    
    private let tickerProvider: TickerProviding
    private let settingsManager: SettingsManaging
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    init(dependencies: any AppDependencies) {
        self.tickerProvider = dependencies.tickerProvider
        self.settingsManager = dependencies.settingsManager
        
        // Subscribe to the provider to get the server's running state.
        tickerProvider.isRunningPublisher
            .assign(to: &$isServerRunning)
            
        // Subscribe to the settings manager to get the true server port.
        settingsManager.settingsPublisher
            .map(\.serverPort)
            .removeDuplicates()
            .sink { [weak self] newPort in
                self?.currentServerPort = newPort
                // When the true port changes, update the text field as well.
                self?.editedPortText = String(newPort)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Intents
    
    func startServer() {
        tickerProvider.start()
    }
    
    func stopServer() {
        tickerProvider.stop()
    }
    
    /// Commits the edited port number to the global app settings.
    /// The TickerProvider will reactively see this change and restart itself.
    func applyPortChange() {
        guard let newPort = Int(editedPortText) else { return }
        settingsManager.modify { settings in
            settings.serverPort = newPort
        }
    }
    
    /// Discards any changes made in the text field and reverts to the current setting.
    func revertPortChange() {
        self.editedPortText = String(currentServerPort)
    }
}
