//
//  PersistentFrame.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import SwiftUI
extension View {
    /// A modifier to automatically save and load a window's frame to persistence.
    /// - Parameters:
    ///   - key: A unique string identifying this window (e.g., "mainWindow").
    ///   - persistence: The persistence service to use for saving and loading.
    func persistentFrame(forKey key: String, persistence: PersistenceHandling) -> some View {
        self.modifier(PersistentWindowFrame(forKey: key, persistence: persistence))
    }
}
