//
//  TradeChecklistView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Main Content View

struct TradeChecklistView_Content: View {
    
    @StateObject private var viewModel: TradeChecklistViewModel
    
    init(dependencies: any AppDependencies, tradeIdea: TradeIdea) {
        // Initialize the ViewModel with the specific TradeIdea it needs to manage.
        _viewModel = StateObject(wrappedValue: TradeChecklistViewModel(tradeIdea: tradeIdea, dependencies: dependencies))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ChecklistHeaderView(viewModel: viewModel)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading Template...")
                Spacer()
            } else if let checklist = viewModel.checklist {
                List {
                    ForEach(checklist.sections) { section in
                        CollapsibleSectionView(
                            title: section.title,
                            isExpanded: viewModel.bindingForSectionExpansion(for: section.id)
                        ) {
                            ForEach(section.items) { item in
                                ChecklistItemRowView(item: item, viewModel: viewModel, tradeIdea: viewModel.tradeIdea)
                            }
                        }
                    }
                }
            }
        }
        .task {
            // Load the checklist template when the view appears.
            await viewModel.load()
        }
    }
}

// MARK: - Subviews

/// The custom header for the checklist detail view.
private struct ChecklistHeaderView: View {
    @ObservedObject var viewModel: TradeChecklistViewModel
    
    var body: some View {
        HStack(alignment: .center) {
            // The interactive status button on the left.
            StatusButton(
                status: viewModel.tradeIdea.status,
                onSetTaken: { viewModel.updateStatus(to: .taken) },
                onSetRejected: { viewModel.updateStatus(to: .rejected) },
                onSetIdea: { viewModel.updateStatus(to: .idea) }
            )
            
            // The main title with ticker and date.
            VStack(alignment: .leading) {
                Text(viewModel.title)
                    .font(.title)
                    .fontWeight(.bold)
                Text(viewModel.tradeIdea.createdAt.formatted(date: .long, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
            
            // Button to open the charting service.
            Button {
                viewModel.openInChartingService()
            } label: {
                Image(systemName: "chart.bar.xaxis")
                Text("Chart")
            }
            
            Button {
                Task { await viewModel.generateAndExportReport() }
            } label: {
                Image(systemName: "square.and.arrow.up")
                Text("Export")
            }
            .disabled(viewModel.isLoading || viewModel.checklist == nil)
        }
        .padding()
    }
}

// MARK: - Public Loader View & Preview

/// The public-facing "loader" view. It takes a TradeIdea to display.
struct TradeChecklistView: View {
    @EnvironmentObject private var dependencies: DependencyContainer
    let tradeIdea: TradeIdea
    
    var body: some View {
        TradeChecklistView_Content(dependencies: dependencies, tradeIdea: tradeIdea)
    }
}

#Preview {
    // We create a helper wrapper view to handle the async data loading for the preview.
    struct PreviewWrapper: View {
        // State to hold the asynchronously loaded idea.
        @State private var tradeIdea: TradeIdea?
        
        // The dependencies are created once.
        let previewDependencies = PreviewDependencyContainer()
        
        var body: some View {
            // If we have successfully loaded the idea, show the content view.
            if let idea = tradeIdea {
                TradeChecklistView_Content(dependencies: previewDependencies, tradeIdea: idea)
                    .frame(width: 500, height: 800)
            } else {
                // Otherwise, show a loading indicator and run the async task.
                ProgressView("Loading Preview...")
                    .task {
                        // When this view appears, this async task runs.
                        // The 'as!' is safe here because we control the concrete type in the preview.
                        if let firstIdea = await (previewDependencies.tradeIdeaManager as! PlaceholderTradeIdeaManager).fetchIdeas(for: Date()).first {
                            // Once the data is fetched, update the state to trigger a re-render.
                            self.tradeIdea = firstIdea
                        }
                    }
            }
        }
    }
    
    // Return an instance of our wrapper view.
    return PreviewWrapper()
}
