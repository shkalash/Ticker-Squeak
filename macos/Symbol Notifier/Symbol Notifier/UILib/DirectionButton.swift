import SwiftUI
import AppKit

struct DirectionButton: NSViewRepresentable {
    @Binding var item: SymbolItem

    func makeNSView(context: Context) -> ClickableView {
        let view = ClickableView()
        view.configure(with: item, binding: $item)
        return view
    }

    func updateNSView(_ nsView: ClickableView, context: Context) {
        nsView.configure(with: item, binding: $item)
    }

    class ClickableView: NSView {
        var hostingView: NSHostingView<AnyView>?
        var item: SymbolItem?
        var binding: Binding<SymbolItem>?

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            self.wantsLayer = true
        }

        required init?(coder decoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func configure(with item: SymbolItem, binding: Binding<SymbolItem>) {
            self.item = item
            self.binding = binding

            // Remove old hosting view
            hostingView?.removeFromSuperview()

            let icon = makeIcon(for: item)
            let host = NSHostingView(rootView: AnyView(icon))
            host.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(host)

            NSLayoutConstraint.activate([
                host.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                host.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                host.topAnchor.constraint(equalTo: self.topAnchor),
                host.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                self.widthAnchor.constraint(equalToConstant: 48),
                self.heightAnchor.constraint(equalToConstant: 28)
            ])

            hostingView = host
        }

        private func makeIcon(for item: SymbolItem) -> some View {
            Group {
                switch item.direction {
                case .none:
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Image(systemName: "chart.line.downtrend.xyaxis")
                    }
                    .foregroundColor(.primary)
                case .bullish:
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                case .bearish:
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .foregroundColor(.red)
                }
            }
            .frame(width: 48, height: 28)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(6)
        }

        override func mouseDown(with event: NSEvent) {
            guard var item = binding?.wrappedValue else { return }
            item.direction = .bullish
            binding?.wrappedValue = item
        }

        override func rightMouseDown(with event: NSEvent) {
            guard var item = binding?.wrappedValue else { return }
            item.direction = .bearish
            binding?.wrappedValue = item
        }
    }
}
