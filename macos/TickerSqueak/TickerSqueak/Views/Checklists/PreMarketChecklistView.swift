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
                                                if let date = viewModel.checklistDate {
                                                            MultiImageWellView(
                                                                imageFileNames: stateBinding.imageFileNames,
                                                                // Create the correct context for the pre-market checklist.
                                                                context: .preMarket(date: date),
                                                                onPaste: { images in
                                                                    Task { await viewModel.savePastedImages(images, forItemID: item.id) }
                                                                },
                                                                onDelete: { filename in
                                                                    viewModel.deletePastedImage(filename: filename, forItemID: item.id)
                                                                }
                                                            )
                                                        } else {
                                                            // If there's no date, we can't create the context, so show a placeholder.
                                                            Text("Date not available for image context.")
                                                                .foregroundColor(.secondary)
                                                                .font(.caption)
                                                        }
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
