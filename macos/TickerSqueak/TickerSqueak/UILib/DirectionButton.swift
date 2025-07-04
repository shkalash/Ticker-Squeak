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

struct DirectionButton: View {
    let direction: TickerItem.Direction
    
    // Add the style property back.
    let style: DirectionButtonStyle
    
    let onSetBullish: () -> Void
    let onSetBearish: () -> Void
    let onSetNeutral: () -> Void
    
    // Update the init to accept the style, with a default value.
    init(
        direction: TickerItem.Direction,
        style: DirectionButtonStyle = .default,
        onSetBullish: @escaping () -> Void,
        onSetBearish: @escaping () -> Void,
        onSetNeutral: @escaping () -> Void
    ) {
        self.direction = direction
        self.style = style
        self.onSetBullish = onSetBullish
        self.onSetBearish = onSetBearish
        self.onSetNeutral = onSetNeutral
    }
    
    var body: some View {
        MultiClickButton(
            content: { iconView },
            onLeftClick: onSetBullish,
            onRightClick: onSetBearish,
            onMiddleClick: onSetNeutral
        )
        // Use the style properties to configure the frame and background.
        .frame(width: style.frame.width, height: style.frame.height)
        .background(style.backgroundColor)
        .cornerRadius(style.cornerRadius)
    }
    
    @ViewBuilder
    private var iconView: some View {
        switch direction {
        case .bullish:
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundColor(.green)
        case .bearish:
            Image(systemName: "chart.line.downtrend.xyaxis")
                .foregroundColor(.red)
        case .none:
            // This switch now correctly handles the different styles for the "none" state.
            switch style.noneDirectionStyle {
            case .flat:
                Image(systemName: "chart.line.flattrend.xyaxis")
                    .foregroundColor(.primary)
            case .upAndDown:
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Image(systemName: "chart.line.downtrend.xyaxis")
                }
                .foregroundColor(.primary)
            }
        }
    }
}
