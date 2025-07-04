//
//  MultiClickButton.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import SwiftUI
import AppKit

// MARK: - 1. The Generic Base Button

/// A generic, reusable view that captures distinct left, right, and middle mouse clicks
/// and displays custom content provided to it.
struct MultiClickButton<Content: View>: NSViewRepresentable {
    
    /// The custom SwiftUI view to be displayed inside the button.
    @ViewBuilder let content: () -> Content
    
    // Action closures for the different click types.
    let onLeftClick: () -> Void
    let onRightClick: () -> Void
    let onMiddleClick: () -> Void

    func makeNSView(context: Context) -> ClickableHostingView<Content> {
        // Create the custom NSView, passing the content and actions from the coordinator.
        return ClickableHostingView(
            rootView: content(),
            onLeftClick: context.coordinator.onLeftClick,
            onRightClick: context.coordinator.onRightClick,
            onMiddleClick: context.coordinator.onMiddleClick
        )
    }

    func updateNSView(_ nsView: ClickableHostingView<Content>, context: Context) {
        // When state changes, update the content and the action closures in the coordinator.
        nsView.rootView = content()
        context.coordinator.onLeftClick = self.onLeftClick
        context.coordinator.onRightClick = self.onRightClick
        context.coordinator.onMiddleClick = self.onMiddleClick
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onLeftClick: onLeftClick,
            onRightClick: onRightClick,
            onMiddleClick: onMiddleClick
        )
    }

    class Coordinator {
        var onLeftClick: () -> Void
        var onRightClick: () -> Void
        var onMiddleClick: () -> Void

        init(onLeftClick: @escaping () -> Void, onRightClick: @escaping () -> Void, onMiddleClick: @escaping () -> Void) {
            self.onLeftClick = onLeftClick
            self.onRightClick = onRightClick
            self.onMiddleClick = onMiddleClick
        }
    }
}

/// The underlying AppKit view that hosts the SwiftUI content and captures mouse events.
class ClickableHostingView<Content: View>: NSHostingView<Content> {
    var onLeftClick: (() -> Void)?
    var onRightClick: (() -> Void)?
    var onMiddleClick: (() -> Void)?
    
    /// Custom initializer to accept click handlers.
    init(
        rootView: Content,
        onLeftClick: (() -> Void)? = nil,
        onRightClick: (() -> Void)? = nil,
        onMiddleClick: (() -> Void)? = nil
    ) {
        // Assign our custom properties first.
        self.onLeftClick = onLeftClick
        self.onRightClick = onRightClick
        self.onMiddleClick = onMiddleClick
        
        // Then, call the designated initializer of the superclass.
        super.init(rootView: rootView)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
            // This is required for storyboard/XIB compatibility, even if we don't use it.
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor required init(rootView: Content) {
        self.onLeftClick = nil
        self.onRightClick = nil
        self.onMiddleClick = nil
        super.init(rootView: rootView)
    }
    
    override func mouseDown(with event: NSEvent) { onLeftClick?() }
    override func rightMouseDown(with event: NSEvent) { onRightClick?() }
    override func otherMouseDown(with event: NSEvent) {
        if event.buttonNumber == 2 { onMiddleClick?() }
    }
}

