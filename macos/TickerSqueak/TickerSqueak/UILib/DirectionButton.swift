import SwiftUI
import AppKit

/// A struct to hold the styling configuration for the DirectionButton.
struct DirectionButtonStyle {
    enum NoneDirectionStyle{
        case flat
        case upAndDown
    }
    let frame: CGSize
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let noneDirectionStyle: NoneDirectionStyle
    /// The default style used by the button.
    static let `default` = DirectionButtonStyle(
        frame: CGSize(width: 48, height: 28),
        backgroundColor: Color.gray.opacity(0.15),
        cornerRadius: 6,
        noneDirectionStyle : .flat
    )
}


/// A button that uses an underlying NSView to capture distinct left, right, and middle
/// click events, communicating actions back via closures.
struct DirectionButton: NSViewRepresentable {
    
    // MARK: - Inputs
    let direction: TickerItem.Direction
    let style: DirectionButtonStyle
    let onLeftClick: () -> Void
    let onRightClick: () -> Void
    let onMiddleClick: () -> Void

    /// Initializes the DirectionButton.
    /// - Parameters:
    ///   - direction: The current direction state to display.
    ///   - style: The visual style of the button. Defaults to `.default`.
    ///   - onLeftClick: The closure to execute on a left-click.
    ///   - onRightClick: The closure to execute on a right-click.
    ///   - onMiddleClick: The closure to execute on a middle-click.
    init(
        direction: TickerItem.Direction,
        style: DirectionButtonStyle = .default, // The style parameter now has a default value.
        onLeftClick: @escaping () -> Void,
        onRightClick: @escaping () -> Void,
        onMiddleClick: @escaping () -> Void
    ) {
        self.direction = direction
        self.style = style
        self.onLeftClick = onLeftClick
        self.onRightClick = onRightClick
        self.onMiddleClick = onMiddleClick
    }
    
    // MARK: - NSViewRepresentable Lifecycle
    
    func makeNSView(context: Context) -> ClickableNSView {
        let nsView = ClickableNSView()
        // Set the actions from the coordinator. The coordinator holds the closures.
        nsView.onLeftClick = context.coordinator.onLeftClick
        nsView.onRightClick = context.coordinator.onRightClick
        nsView.onMiddleClick = context.coordinator.onMiddleClick
        return nsView
    }

    func updateNSView(_ nsView: ClickableNSView, context: Context) {
        // This is crucial: When the state changes in the ViewModel, this method is called.
        // We update the coordinator with the latest closures (in case they capture new state)
        // and tell the NSView to re-render its SwiftUI content with the new direction icon and style.
        context.coordinator.onLeftClick = self.onLeftClick
        context.coordinator.onRightClick = self.onRightClick
        context.coordinator.onMiddleClick = self.onMiddleClick
        nsView.update(direction: self.direction, style: self.style)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onLeftClick: onLeftClick,
            onRightClick: onRightClick,
            onMiddleClick: onMiddleClick
        )
    }

    // MARK: - Coordinator
    
    /// The coordinator acts as a delegate and holds the action closures,
    /// allowing the NSView to communicate back to the SwiftUI world.
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


// MARK: - The Custom AppKit View

/// The underlying AppKit view that captures mouse events.
class ClickableNSView: NSView {
    
    // MARK: - Properties
    var onLeftClick: (() -> Void)?
    var onRightClick: (() -> Void)?
    var onMiddleClick: (() -> Void)?
    private var hostingView: NSHostingView<AnyView>?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Mouse Events
    
    override func mouseDown(with event: NSEvent) {
        onLeftClick?()
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?()
    }
    
    override func otherMouseDown(with event: NSEvent) {
        // In AppKit, the middle mouse button corresponds to button number 2.
        if event.buttonNumber == 2 {
            onMiddleClick?()
        }
    }

    // MARK: - View Configuration
    
    /// Updates the view by re-rendering the hosted SwiftUI icon with the specified style.
    func update(direction: TickerItem.Direction, style: DirectionButtonStyle) {
        let iconView = makeIcon(for: direction, style: style)
        
        if hostingView == nil {
            // If this is the first time, create and constrain the hosting view.
            let host = NSHostingView(rootView: AnyView(iconView))
            host.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(host)
            NSLayoutConstraint.activate([
                host.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                host.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                host.topAnchor.constraint(equalTo: self.topAnchor),
                host.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
            self.hostingView = host
        } else {
            // If it already exists, just update its rootView.
            hostingView?.rootView = AnyView(iconView)
        }
    }

    /// The SwiftUI view for the icon itself. It now applies the style passed into it.
    @ViewBuilder
    private func makeIcon(for direction: TickerItem.Direction, style: DirectionButtonStyle) -> some View {
        Group {
            switch direction {
            case .none:
                    switch (style.noneDirectionStyle){
                        case .upAndDown:
                            HStack(spacing: 4) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                Image(systemName: "chart.line.downtrend.xyaxis")
                            }
                            .foregroundColor(.primary)
                        case .flat:
                            Image(systemName: "chart.line.flattrend.xyaxis")
                                .foregroundColor(.primary)
                    }
            case .bullish:
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
            case .bearish:
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .foregroundColor(.red)
            }
        }
        .frame(width: style.frame.width, height: style.frame.height)
        .background(style.backgroundColor)
        .cornerRadius(style.cornerRadius)
    }
}
