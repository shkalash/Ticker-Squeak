import SwiftUI

enum ImageType {
    case asset
    case system
}

struct PickerOption: Identifiable {
    var id : Int { tag }
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

    var body: some View {
        ViewThatFits(in: .horizontal) {
            // Attempt 1: The ideal layout with full text labels.
            HStack(spacing: 0) {
                ForEach(options) { option in
                    button(for: option, isCompact: false)
                }
            }
            
            // Attempt 2: The compact fallback layout with icons only.
            HStack(spacing: 0) {
                ForEach(options) { option in
                    button(for: option, isCompact: true)
                }
            }
        }
        .frame(height: 40)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    /// A helper function to create a single button, avoiding code repetition.
    private func button(for option: PickerOption, isCompact: Bool) -> some View {
        Button(action: {
            selection = option.tag
        }) {
            // The content of the button (icon and optional text)
            HStack(spacing: isCompact ? 0 : 8) {
                switch option.imageType {
                case .system:
                    Image(systemName: option.imageName)
                case .asset:
                    Image(option.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                }

                if !isCompact {
                    Text(option.label)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, isCompact ? 10 : 12) // Adjust padding for compact vs full
            .frame(maxWidth: .infinity, minHeight: 40)
            .contentShape(Rectangle())
        }
        .background(selection == option.tag ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(8)
        .buttonStyle(.plain)
    }
}
