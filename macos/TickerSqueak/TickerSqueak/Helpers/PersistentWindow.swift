//
//  PersistentWindow.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - 1. The Data Model & Persistence Key

/// A Codable struct to store the window's frame information.
struct WindowState: Codable {
    let frame: CGRect
}

extension PersistenceKey {
    /// A generic key for persisting the state of a window.
    /// - Parameter name: The unique name for the window being saved (e.g., "mainWindow").
    /// - Returns: A PersistenceKey for a WindowState object.
    static func windowState(name: String) -> PersistenceKey<WindowState> {
        .init(name: "WindowState_\(name)")
    }
}

/// The ViewModifier that applies the persistent frame logic.
struct PersistentWindowFrame: ViewModifier {
    private let persistenceKey: PersistenceKey<WindowState>
    private let persistence: PersistenceHandling
    
    // We store the notification observers in a property to keep them alive.
    @State private var observers: [AnyObject] = []

    init(forKey key: String, persistence: PersistenceHandling) {
        self.persistenceKey = .windowState(name: key)
        self.persistence = persistence
    }

    func body(content: Content) -> some View {
        content
            .background(
                WindowAccessor { window in
                    // On first appearance, load and apply the saved frame.
                    applySavedFrame(to: window)
                    // Set up observers to save the frame on change.
                    setupObservers(for: window)
                }
            )
    }
    
    private func applySavedFrame(to window: NSWindow) {
        if let windowState: WindowState = persistence.loadCodable(for: persistenceKey) {
            window.setFrame(windowState.frame, display: true)
        } else {
            // Provide a sensible default if no state is saved.
            window.setContentSize(NSSize(width: 400, height: 500))
            window.center()
        }
    }
    
    private func setupObservers(for window: NSWindow) {
        // Prevent adding observers multiple times.
        guard observers.isEmpty else { return }
        
        // Save frame on move
        let moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { _ in
            save(window: window)
        }
        
        // Save frame on resize
        let resizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didEndLiveResizeNotification,
            object: window,
            queue: .main
        ) { _ in
            save(window: window)
        }
        
        self.observers = [moveObserver, resizeObserver]
    }
    
    private func save(window: NSWindow) {
        let state = WindowState(frame: window.frame)
        persistence.saveCodable(object: state, for: persistenceKey)
    }
}


