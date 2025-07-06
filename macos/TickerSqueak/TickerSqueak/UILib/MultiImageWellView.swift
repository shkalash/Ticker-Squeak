//
//  MultiImageWellView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//
import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Size Measurement PreferenceKey

/// A PreferenceKey to store and pass up a view's size to its parent.
private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

/// A ViewModifier to apply the preference for reading a view's size.
fileprivate extension View {
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


// MARK: - Main View and Subviews

/// The main container view that orchestrates the image thumbnails and the drop zone.
struct MultiImageWellView: View {
    @Binding var imageFileNames: [String]
    let context: ChecklistContext
    let onPaste: ([NSImage]) -> Void
    let onDelete: (String) -> Void
    
    @EnvironmentObject private var dependencies: DependencyContainer
    @State private var loadedImages: [String: NSImage] = [:]
    @State private var imageToView: NSImage?
    
    // State to hold the measured width of the thumbnail container.
    @State private var thumbnailContainerWidth: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 12) {
                // The ScrollView now has its width explicitly set.
                if (!imageFileNames.isEmpty){
                    ScrollView(.horizontal, showsIndicators: false) {
                        // This inner HStack is what we will measure.
                        HStack(spacing: 16) {
                            ForEach(imageFileNames, id: \.self) { filename in
                                if let image = loadedImages[filename] {
                                    ImageThumbnailView(
                                        image: image,
                                        onDelete: { onDelete(filename) },
                                        onTap: { imageToView = image }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        // Use our helper to read the size of this HStack and store it in our @State variable.
                        .readSize { size in
                            thumbnailContainerWidth = size.width
                        }
                    }
                    .frame(height: 90)
                    // Use the measured width to set the frame. Cap it at 80% of the parent's width.
                    .frame(width: min(thumbnailContainerWidth, geometry.size.width * 0.8))
                }
                // The drop zone greedily fills the rest of the space.
                ImageDropZoneView(onPasteData: { imageDataArray in
                    handlePasted(imageDataArray: imageDataArray)
                })
                .frame(maxWidth: .infinity)
            }
            .animation(.easeInOut, value: imageFileNames.count)
        }
        .frame(minHeight: 90)
        .padding(8)
        .background(Color.black.opacity(0.1))
        .cornerRadius(8)
        .animation(.easeInOut, value: imageFileNames.count)
        .task(id: imageFileNames) {
            await loadImagesFromDisk()
        }
        .sheet(item: $imageToView) { image in
            FullSizeImageViewer(image: image)
        }
    }
    
    private func handlePasted(imageDataArray: [Data]) {
        let newImages = imageDataArray.compactMap { NSImage(data: $0) }
        guard !newImages.isEmpty else { return }
        onPaste(newImages)
        NSPasteboard.general.clearContents()
    }
    
    private func loadImagesFromDisk() async {
        let imagePersister = dependencies.imagePersister
        for filename in imageFileNames where loadedImages[filename] == nil {
            if let data = await imagePersister.loadImageData(withFilename: filename, for: context) {
                if let image = NSImage(data: data) {
                    loadedImages[filename] = image
                }
            }
        }
    }
}

/// A view for a single, interactive image thumbnail.
private struct ImageThumbnailView: View {
    let image: NSImage
    let onDelete: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // The image itself, which the user taps to view full-size.
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60) // Slightly smaller frame
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.5), lineWidth: 1))
                .onTapGesture(perform: onTap)
            
            // The "X" delete button, offset to sit on the corner.
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .red)
                    .shadow(radius: 2)
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6) // Reduced offset
        }
    }
}


/// A view to display a single image in a sheet, now with a better default size.
private struct FullSizeImageViewer: View {
    let image: NSImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // A semi-transparent background for the sheet
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
            
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(40) // Give it some space from the edges

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.6))
            }
            .buttonStyle(.plain)
            .padding()
        }
        // Give the sheet a large, useful default size.
        .frame(minWidth: 800, idealWidth: 1200, minHeight: 400, idealHeight: 800)
    }
}

/// A dedicated drop zone view that passes up raw `Data` to its parent.
private struct ImageDropZoneView: View {
    let onPasteData: ([Data]) -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundColor(.secondary)
            
            Image(systemName: "photo.on.rectangle.angled")
                .font(.title).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: pasteFromClipboard)
        .onPasteCommand(of: [UTType.image]) { providers in
            Task {
                let pastedImageData = await loadImageData(from: providers)
                if !pastedImageData.isEmpty {
                    onPasteData(pastedImageData)
                }
            }
        }
    }
    
    private func pasteFromClipboard() {
        if NSPasteboard.general.canReadObject(forClasses: [NSImage.self], options: [:]) {
            if let images = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: [:]) as? [NSImage], !images.isEmpty {
                let imageDataArray = images.compactMap { $0.pngData() }
                onPasteData(imageDataArray)
            }
        }
    }
    
    private func loadImageData(from providers: [NSItemProvider]) async -> [Data] {
        let loadedData: [Data] = await withTaskGroup(of: Data?.self) { group in
            var results: [Data] = []
            for provider in providers {
                if provider.canLoadObject(ofClass: NSImage.self) {
                    group.addTask {
                        return await withCheckedContinuation { continuation in
                            _ = provider.loadObject(ofClass: NSImage.self) { image, error in
                                guard let nsImage = image as? NSImage else {
                                    continuation.resume(returning: nil)
                                    return
                                }
                                continuation.resume(returning: nsImage.pngData())
                            }
                        }
                    }
                }
            }
            for await data in group where data != nil {
                results.append(data!)
            }
            return results
        }
        return loadedData
    }
}



