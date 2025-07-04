//
//  TradeIdeasListView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import SwiftUI

// MARK: - Main Content View

struct TradeIdeasListView_Content: View {
    
    @StateObject private var viewModel: TradeIdeasListViewModel
    
    // State for the "New Idea" sheet and programmatic navigation
    @State private var isShowingNewIdeaSheet = false
    @State private var navigationPath = NavigationPath()
    
    private let dependencies: any AppDependencies

    init(dependencies: any AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: TradeIdeasListViewModel(dependencies: dependencies))
    }

    var body: some View {
        // NavigationStack is the root for handling the list-to-detail flow.
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Toolbar for date picking and creating new ideas
                HStack {
                    DatePicker("Date:", selection: $viewModel.selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .fixedSize()
                    
                    Spacer()
                    
                    Button {
                        isShowingNewIdeaSheet = true
                    } label: {
                        Image(systemName: "plus")
                        Text("New Idea")
                    }
                }
                .padding()

                // The list of trade ideas for the selected day
                List {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.ideas.isEmpty {
                        Text("No trade ideas logged for this day.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.ideas) { idea in
                            NavigationLink(value: idea) {
                                TradeIdeaListRow(
                                    idea: idea,
                                    onUpdateDirection: { newDirection in
                                        viewModel.updateDirection(for: idea.id, to: newDirection)
                                    },
                                    onUpdateStatus: { newStatus in
                                        viewModel.updateStatus(for: idea.id, to: newStatus)
                                    },
                                    onDelete: {
                                        viewModel.deleteIdea(id: idea.id)
                                    }
                                )
                            }
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                // This modifier catches the 'value' from the NavigationLink and builds the destination view.
                .navigationDestination(for: TradeIdea.self) { idea in
                    // When a link is tapped, we create the detail view for that specific idea.
                    TradeChecklistView_Content(dependencies: dependencies, tradeIdea: idea)
                }
            }
            .navigationTitle("Trade Ideas")
            .sheet(isPresented: $isShowingNewIdeaSheet) {
                NewTradeIdeaSheet { ticker in
                    Task {
                        // Call the updated create method
                        await viewModel.createAndNavigate(toTicker: ticker)
                    }
                }
            }
            // This handles programmatic navigation requests from other parts of the app
            .onChange(of: viewModel.navigationRequest) { _, newRequest in
                if let idea = newRequest {
                    navigationPath.append(idea)
                }
            }
            .task {
                        await viewModel.onAppear()
            }
        }
    }
}

// MARK: - Subviews

private struct TradeIdeaListRow: View {
    let idea: TradeIdea
    
    // Add closures for the new actions
    let onUpdateDirection: (TickerItem.Direction) -> Void
    let onUpdateStatus: (IdeaStatus) -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // New StatusButton
            StatusButton(
                status: idea.status,
                onSetTaken: { onUpdateStatus(.taken) },
                onSetRejected: { onUpdateStatus(.rejected) },
                onSetIdea: { onUpdateStatus(.idea) }
            )
            
            VStack(alignment: .leading) {
                Text(idea.ticker).fontWeight(.bold)
                Text(idea.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption).foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .leading)
            
            // Refactored DirectionButton
            DirectionButton(
                direction: idea.direction,
                onSetBullish: { onUpdateDirection(.bullish) },
                onSetBearish: { onUpdateDirection(.bearish) },
                onSetNeutral: { onUpdateDirection(.none) }
            )

            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
            .help("Delete Idea")
            
        }
        .padding(.vertical, 4)
    }
}


/// A simple view presented as a sheet to get the ticker for a new trade idea.
private struct NewTradeIdeaSheet: View {
    @State private var ticker: String = ""
    let onCreate: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("New Trade Idea").font(.title2)
            TextField("Ticker Symbol (e.g., AAPL)", text: $ticker)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 200)
            
            HStack {
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Create") {
                    onCreate(ticker)
                    dismiss()
                }.keyboardShortcut(.defaultAction)
                .disabled(ticker.isEmpty)
            }
        }
        .padding()
    }
}


// MARK: - Public Loader View & Preview

/// The public-facing "loader" view. Its only job is to get dependencies and pass them on.
struct TradeIdeasListView: View {
    @EnvironmentObject private var dependencies: DependencyContainer

    var body: some View {
        TradeIdeasListView_Content(dependencies: dependencies)
    }
}

#Preview {
    // The preview creates the placeholder container and injects it.
    let previewDependencies = PreviewDependencyContainer()
    
    // We instantiate the _Content view directly for the preview.
    return TradeIdeasListView_Content(dependencies: previewDependencies)
        .frame(width: 400, height: 600)
}
