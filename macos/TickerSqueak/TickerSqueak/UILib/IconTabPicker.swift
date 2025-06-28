import SwiftUI

// Enum and Struct definitions remain the same
enum ImageType {
    case asset
    case system
}

struct PickerOption: Identifiable {
    let id = { tag }
    let label: String
    let imageName: String
    let tag: Int
    let imageType: ImageType

    init(label: String, imageName: String, tag: Int, imageType: ImageType = .system) {
        self.label = label
        self.imageName = imageName
        self.tag = tag
        self.imageType = imageType
    }
}


struct IconTabPicker: View {
    @Binding var selection: Int
    var options: [PickerOption]

    // State to track the mode and the ideal width of the full content
    @State private var isCompact = false
    @State private var fullContentWidth: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            // The main, visible content
            HStack(spacing: 0) {
                ForEach(options) { option in
                    Button(action: {
                        selection = option.tag
                    }) {
                        buttonContent(for: option, isCompact: isCompact)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .contentShape(Rectangle())
                    }
                    .background(selection == option.tag ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                    .buttonStyle(.plain)
                }
            }
            // This background view is used ONLY for measuring the ideal size
            .background(
                HStack(spacing: 0) {
                    ForEach(options) { option in
                        // Always render the FULL content for measurement
                        buttonContent(for: option, isCompact: false)
                            .frame(minHeight: 40)
                    }
                }
                .fixedSize() // Crucial: tells the HStack to take its ideal width
                .readSize { size in
                    fullContentWidth = size.width
                }
                .hidden() // We don't need to see the measurement view
            )
            // This modifier detects changes and updates the compact mode
            .onChange(of: geometry.size.width, initial: true) { oldWidth, newWidth in
                updateCompactMode(availableWidth: newWidth)
            }
            .onChange(of: fullContentWidth) {
                updateCompactMode(availableWidth: geometry.size.width)
            }
        }
        .frame(height: 40)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    // A helper function to build the button's content, avoiding repetition
    @ViewBuilder
    private func buttonContent(for option: PickerOption, isCompact: Bool) -> some View {
        HStack(spacing: isCompact ? 0 : 8) { // No spacing if compact
            // Conditionally render the correct image type
            switch option.imageType {
            case .system:
                Image(systemName: option.imageName)
            case .asset:
                Image(option.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }

            // Only show the text if not in compact mode
            if !isCompact {
                Text(option.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }
    
    // Logic to decide if we should be in compact mode
    private func updateCompactMode(availableWidth: CGFloat) {
        // Only switch to compact if the ideal width is known and larger than available
        if fullContentWidth > 0 && availableWidth < fullContentWidth {
            isCompact = true
        } else {
            isCompact = false
        }
    }
}
// A PreferenceKey to store and pass up the view's size
private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

// A ViewModifier to apply the preference
extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}
