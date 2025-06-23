import SwiftUI

enum ImageType {
    case asset
    case system
}

struct PickerOption {
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
        HStack(spacing: 0) { 
            ForEach(options, id: \.tag) { option in
                Button(action: {
                    selection = option.tag
                }) {
                    HStack(spacing: 8) { // Add spacing between icon and text
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
                        
                        Text(option.label)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7) // Allow font to shrink
                    }
                    // Add some internal padding
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .contentShape(Rectangle())
                }
                .background(selection == option.tag ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(8)
                .buttonStyle(.plain)
            }
        }
        // Add padding around the whole container
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
