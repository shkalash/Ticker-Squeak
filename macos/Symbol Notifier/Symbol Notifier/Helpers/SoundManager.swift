//
//  SoundManager.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/23/25.
//


import Foundation
import AppKit // Needed for NSSound

actor SoundManager {
    // Create a shared instance so the whole app uses the same one.
    static let shared = SoundManager()

    // This property is protected by the actor.
    private var lastPlayedTime: Date?
    
    func setMuted(_ muted: Bool) {
        self.muted = muted
    }
    
    private var muted: Bool = false

    /// Plays a sound by name, but only if the cooldown period has passed.
    /// - Parameters:
    ///   - soundName: The name of the sound file (e.g., "sound01").
    ///   - cooldown: The minimum time that must pass before playing the sound again, in seconds.
    func playSoundForNotification(named soundName: String, cooldown: TimeInterval) {
        if (muted){
            return
        }
        guard soundName.isEmpty == false else {
            print("Empty sound requested. Ignoring.")
            return
        }
        
        let now = Date()

        // If a sound was played before, check if enough time has passed.
        if let lastPlayed = lastPlayedTime {
            if now.timeIntervalSince(lastPlayed) < cooldown {
                // Not enough time has passed, so we ignore this request.
                print("Cooldown active. Ignoring sound request.")
                return
            }
        }
        
        // If we're here, it's time to play the sound.
        NSSound(named: soundName)?.play()
        
        // Update the last played time to now.
        lastPlayedTime = now
    }
}
