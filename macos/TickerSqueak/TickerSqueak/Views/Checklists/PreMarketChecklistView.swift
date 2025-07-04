// PreMarketChecklistView.swift

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PreMarketChecklistView_Content: View {
    
    @StateObject private var viewModel: PreMarketChecklistViewModel

    init(dependencies: any AppDependencies) {
        _viewModel = StateObject(wrappedValue: PreMarketChecklistViewModel(dependencies: dependencies))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading) {
                                Text(viewModel.title).font(.title2).fontWeight(.bold)
                                
                                if let date = viewModel.checklistDate {
                                    Text(date.formatted(date: .long, time: .omitted))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button {
                                Task { await viewModel.startNewDay() }
                            } label: {
                                Image(systemName: "forward.fill")
                                Text("New Day")
                            }
                            .disabled(viewModel.isLoading || viewModel.checklist == nil)

                            Button {
                                Task { await viewModel.generateAndExportReport() }
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export")
                            }
                            .disabled(viewModel.isLoading || viewModel.checklist == nil)
                        }
                        .padding()

            // Main content area
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading Checklist...")
                Spacer()
            } else if let checklist = viewModel.checklist {
                List {
                    ForEach(checklist.sections) { section in
                        DisclosureGroup(
                            isExpanded: viewModel.bindingForSectionExpansion(for: section.id),
                            content: {
                                // The content is the list of items for this section
                                ForEach(section.items) { item in
                                    let stateBinding = viewModel.binding(for: item.id)
                                    
                                    // Switch on the item type to render the correct UI
                                    switch item.type {
                                        case .checkbox(let text):
                                            Toggle(text, isOn: stateBinding.isChecked)
                                                .padding(.vertical, 4)
                                            
                                        case .textInput(let prompt):
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(prompt).font(.callout).foregroundColor(.secondary)
                                                TextEditor(text: stateBinding.userText)
                                                    .font(.body)
                                                    .frame(minHeight: 80)
                                                    .padding(4)
                                                    .background(Color(nsColor: .textBackgroundColor))
                                                    .cornerRadius(6)
                                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.5)))
                                            }
                                            .padding(.vertical, 4)
                                            
                                        case .image(let caption):
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(caption).font(.callout).foregroundColor(.secondary)
                                                MultiImagePlaceholderView(
                                                    imageFileNames: stateBinding.imageFileNames,
                                                    onPaste: { images in
                                                        Task { await viewModel.savePastedImages(images, forItemID: item.id) }
                                                    }
                                                )
                                            }
                                            .padding(.vertical, 4)
                                    }
                                }
                            },
                            label: {
                                // The label is the section title
                                Text(section.title)
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                        )
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                
            } else if viewModel.error != nil {
                VStack {
                    Image(systemName: "xmark.octagon.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Failed to load checklist.")
                        .padding(.top, 4)
                    Text(viewModel.error?.localizedDescription ?? "An unknown error occurred.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .task {
            // Load data when the view first appears.
            if viewModel.checklist == nil {
                await viewModel.load()
            }
        }
    }
}

struct MultiImagePlaceholderView: View {
    @Binding var imageFileNames: [String]
    let onPaste: ([NSImage]) -> Void
    
    @State private var images: [NSImage] = []
    // Dependencies to load images would be passed here in a real app
    
    var body: some View {
        // A simple representation for now.
        // A full implementation would load images from the file system.
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundColor(.secondary)
            
            if imageFileNames.isEmpty {
                Text("Paste Screenshots Here")
                    .foregroundColor(.secondary)
            } else {
                Text("\(imageFileNames.count) image(s) attached")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minHeight: 80)
        .onPasteCommand(of: [UTType.image]) { providers in
            var newImages: [NSImage] = []
            let dispatchGroup = DispatchGroup()
            for provider in providers {
                dispatchGroup.enter()
                if provider.canLoadObject(ofClass: NSImage.self) {
                    _ = provider.loadObject(ofClass: NSImage.self) { image, _ in
                        if let nsImage = image as? NSImage {
                            newImages.append(nsImage)
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                if !newImages.isEmpty {
                    onPaste(newImages)
                }
            }
        }
    }
}

// Loader view and Preview remain the same
struct PreMarketChecklistView: View {
    @EnvironmentObject private var dependencies: DependencyContainer
    var body: some View {
        PreMarketChecklistView_Content(dependencies: dependencies)
    }
}

#Preview {
    let previewDependencies = PreviewDependencyContainer()
    PreMarketChecklistView_Content(dependencies: previewDependencies)
        .frame(width: 450, height: 700)
}
