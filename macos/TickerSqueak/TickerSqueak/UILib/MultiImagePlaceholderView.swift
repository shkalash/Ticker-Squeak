//
//  MultiImagePlaceholderView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//
import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct MultiImagePlaceholderView: View {
    @Binding var imageFileNames: [String]
    let onPaste: ([NSImage]) -> Void
    
    @State private var displayedImages: [NSImage] = []

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundColor(.secondary)

            if displayedImages.isEmpty && imageFileNames.isEmpty {
                Text("Paste or Click to Add Screenshot")
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack {
                        ForEach(0..<displayedImages.count, id: \.self) { index in
                            Image(nsImage: displayedImages[index])
                                .resizable().aspectRatio(contentMode: .fit)
                        }
                    }.padding(.horizontal, 4)
                }
            }
        }
        .frame(minHeight: 80)
        .onTapGesture { pasteFromClipboard() }
        .onPasteCommand(of: [UTType.image]) { providers in
            Task {
                // The helper function now returns an array of safe [Data]
                let pastedImageData = await loadImageData(from: providers)
                if !pastedImageData.isEmpty {
                    // This function is on the Main Actor, so it's safe to handle the data here.
                    handlePasted(imageDataArray: pastedImageData)
                }
            }
        }
    }

    /// This function is now on the Main Actor. It receives safe Data and converts it back to NSImage.
    private func handlePasted(imageDataArray: [Data]) {
        // Convert Data back to NSImage safely on the main thread.
        let newImages = imageDataArray.compactMap { NSImage(data: $0) }
        
        guard !newImages.isEmpty else { return }
        
        self.displayedImages.append(contentsOf: newImages)
        onPaste(newImages)
        NSPasteboard.general.clearContents()
    }

    private func pasteFromClipboard() {
        if NSPasteboard.general.canReadObject(forClasses: [NSImage.self], options: [:]) {
            guard let images = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: [:]) as? [NSImage],
                  !images.isEmpty else { return }
            
            // Convert to Data before handling.
            let imageDataArray = images.compactMap { $0.pngData() }
            handlePasted(imageDataArray: imageDataArray)
        }
    }

    /// THIS IS THE CORE FIX: This function now returns `[Data]` instead of `[NSImage]`.
    /// It performs the conversion from NSImage to Data on the background thread.
    private func loadImageData(from providers: [NSItemProvider]) async -> [Data] {
        await withTaskGroup(of: Data?.self) { group in
            var results: [Data] = []
            
            for provider in providers {
                if provider.canLoadObject(ofClass: NSImage.self) {
                    group.addTask {
                        // This task runs on a background thread.
                        return await withCheckedContinuation { continuation in
                            _ = provider.loadObject(ofClass: NSImage.self) { image, error in
                                // 1. Get the NSImage.
                                guard let nsImage = image as? NSImage else {
                                    continuation.resume(returning: nil)
                                    return
                                }
                                // 2. Convert to PNG Data immediately.
                                let pngData = nsImage.pngData()
                                // 3. Resume with the safe, Sendable Data object.
                                continuation.resume(returning: pngData)
                            }
                        }
                    }
                }
            }
            
            for await data in group {
                if let data = data {
                    results.append(data)
                }
            }
            
            return results
        }
    }
}
