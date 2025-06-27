//
//  SoundLibrary.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Foundation
import AppKit // Required for NSSound

struct SoundLibrary: Codable, Equatable {
    
    /// Defines the different types of sounds the application can play.
    /// Conforming to String and CaseIterable makes it easy to save and loop through.
    enum SoundType: String, Codable, CaseIterable {
        case alert = "Normal Alert"
        case highPriorityAlert = "High-Priority Alert"
    }
    
    /// The private dictionary holding the mapping from a sound type to its sound file name.
    private var sounds: [SoundType: String] = [:]

    /// Initializes the sound library.
    /// It iterates through all possible sound types and assigns a default sound.
    init() {
        // Get all available sound names from the app's bundle.
        let availableSounds = NSSound.bundledSoundNames
        // Create a shuffled copy of the sounds to pull unique names from.
        var uniqueShuffledSounds = availableSounds.shuffled()
        
        // Using CaseIterable to loop through all cases of the enum.
        // This makes sure that if you add a new SoundType, it gets a default value automatically.
        for type in SoundType.allCases {
            // Pull the last sound from the shuffled list to ensure uniqueness.
            // If the list is empty (more sound types than sounds), fall back to any random sound.
            sounds[type] = uniqueShuffledSounds.popLast() ?? availableSounds.randomElement() ?? ""
        }
    }
    
    // MARK: - Public Accessors
    
    /// Retrieves the sound file name for a given sound type.
    /// - Parameter type: The type of sound to look up.
    /// - Returns: The name of the sound file as a String.
    func getSound(for type: SoundType) -> String {
        // Use a nil-coalescing operator to gracefully handle the unlikely event a sound is not found.
        return sounds[type] ?? ""
    }
    
    /// Updates the sound file name for a given sound type.
    /// - Parameters:
    ///   - type: The sound type to update.
    ///   - soundName: The new sound file name.
    mutating func setSound(for type: SoundType, to soundName: String) {
        sounds[type] = soundName
    }

    // MARK: - Codable Conformance
    
    // We need a custom implementation because the dictionary key `SoundType` is not a standard String or Int.
    
    private struct CodingKeys {
        static let sounds = "sounds"
    }

    init(from decoder: Decoder) throws {
        self.init() // Start with a default library to ensure all keys exist.
        
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        
        // Decode the dictionary as [String: String]
        for key in container.allKeys {
            if let soundType = SoundType(rawValue: key.stringValue),
               let soundName = try? container.decode(String.self, forKey: key) {
                // Update the library with the loaded sound name.
                self.sounds[soundType] = soundName
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        
        // Encode the dictionary by converting the SoundType key to its String rawValue.
        for (soundType, soundName) in sounds {
            try container.encode(soundName, forKey: DynamicCodingKey(stringValue: soundType.rawValue))
        }
    }
}

/// A helper struct to allow dynamic keys during Codable operations.
private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    init(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?
    init?(intValue: Int) {
        return nil
    }
}
