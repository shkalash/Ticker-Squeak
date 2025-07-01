//
//  AlwaysOnTopModifier.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/1/25.
//


// AlwaysOnTopModifier.swift
import SwiftUI

/// A view modifier that attempts to bring its containing window to the front and keep it there.
struct AlwaysOnTopModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .background(AlwaysOnTopWindowAccessror()) // Add the accessor to the background
    }

    /// A helper view to access the window object
    private struct AlwaysOnTopWindowAccessror: NSViewRepresentable {
        func makeNSView(context: Context) -> NSView {
            let view = NSView()
            // Using a DispatchQueue to delay the configuration slightly ensures that
            // the window is fully available before we try to modify it.
            DispatchQueue.main.async {
                if let window = view.window {
                    configure(window: window)
                }
            }
            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {}

        /// This is where the magic happens.
        private func configure(window: NSWindow) {
            // This level is higher than normal windows, even alerts and modal dialogs.
            // It will appear above the Dock and even the menu bar.
            // .statusBar is another high-level option.
            window.level = .screenSaver

            // This ensures the window is visible on all Spaces, including when
            // another app is in full-screen mode.
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            
            // Optionally, you can make the window movable by its background.
            window.isMovableByWindowBackground = true
            
            // Optionally, prevent the window from being resized.
            // window.styleMask.remove(.resizable)
        }
    }
}

// Extension to make the modifier easier to use
extension View {
    func alwaysOnTop() -> some View {
        self.modifier(AlwaysOnTopModifier())
    }
}
