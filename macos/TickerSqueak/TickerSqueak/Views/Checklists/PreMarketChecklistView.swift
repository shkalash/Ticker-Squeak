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
                
                Button(action: viewModel.expandAllSections) {
                    Image(systemName: "chevron.down.square")
                }
                .help("Expand All Sections")
                // Disable if the checklist isn't loaded or if all sections are already expanded
                .disabled(viewModel.checklist == nil || viewModel.expandedSectionIDs.count == viewModel.checklist?.sections.count)
                
                Button(action: viewModel.collapseAllSections) {
                    Image(systemName: "chevron.up.square")
                }
                .help("Collapse All Sections")
                // Disable if no sections are expanded
                .disabled(viewModel.expandedSectionIDs.isEmpty)
                
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
                        CollapsibleSectionView(
                            title: section.title,
                            isExpanded: viewModel.bindingForSectionExpansion(for: section.id)
                        ) {
                            ForEach(section.items) { item in
                                ChecklistItemRowView(item: item, viewModel: viewModel)
                            }
                        }
                    }
                }.id(viewModel.refreshID)
                
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
