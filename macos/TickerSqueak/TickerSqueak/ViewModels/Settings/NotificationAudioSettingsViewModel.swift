//
//  NotificationAudioSettingsViewModel.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import Foundation
import Combine
import AppKit // For NSSound

/// The ViewModel for the NotificationAudioSettingsView. It manages the state and actions
/// related to selecting sounds for different notification types.
@MainActor
class NotificationAudioSettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The current sound library configuration, fetched from the SettingsManager.
    @Published private(set) var soundLibrary: SoundLibrary = SoundLibrary()
    
    /// The list of all system sounds available to the user.
    let availableSounds: [String] = NSSound.bundledSoundNames

    // MARK: - Private Properties
    
    private let settingsManager: SettingsManaging
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle
    
    init(dependencies: any AppDependencies) {
        self.settingsManager = dependencies.settingsManager
        
        // Subscribe to the settings publisher to always have the latest sound library.
        settingsManager.settingsPublisher
            .map(\.soundLibrary)
            .removeDuplicates() // Only update if the library has actually changed
            .assign(to: &$soundLibrary)
    }
    
    // MARK: - Public Intents
    
    /// Updates the sound for a specific notification type in the global settings.
    /// - Parameters:
    ///   - type: The `SoundLibrary.SoundType` to update.
    ///   - soundName: The new sound file name to assign.
    func setSound(for type: SoundLibrary.SoundType, to soundName: String) {
        settingsManager.modify { settings in
            settings.soundLibrary.setSound(for: type, to: soundName)
        }
    }
    
    /// Plays the currently selected sound for a given notification type.
    /// - Parameter type: The `SoundLibrary.SoundType` whose sound should be played.
    func playSound(for type: SoundLibrary.SoundType) {
        let soundName = soundLibrary.getSound(for: type)
        NSSound(named: soundName)?.play()
    }
}
