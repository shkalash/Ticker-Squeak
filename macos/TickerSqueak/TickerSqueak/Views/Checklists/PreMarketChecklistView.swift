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
            ViewThatFits(in: .horizontal) {
                // Attempt 1: The ideal single-line layout
                HStack() {
                    Text(viewModel.title).font(.title2).fontWeight(.bold)
                    HeaderToolbar(viewModel: viewModel)
                }
                .padding()
                
                // Attempt 2: The fallback two-line layout
                VStack(spacing: 0) {
                    Text(viewModel.title).font(.title2).fontWeight(.bold).padding(.top)
                    HStack{
                        HeaderToolbar(viewModel: viewModel)
                    }.padding()
                }
            }
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
                }.id(viewModel.refreshUUID)
                
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
            await viewModel.load()
        }
    }
}

private struct HeaderToolbar : View {
    @ObservedObject var viewModel: PreMarketChecklistViewModel
    @State private var showingCalendar: Bool = false
    var body: some View {
        Button {
            showingCalendar = true
        } label: {
            HStack {
                Text(viewModel.selectedDate.formatted(Date.FormatStyle()
                    .month(.defaultDigits)
                    .day(.defaultDigits)
                    .year(.twoDigits)))
                Image(systemName: "calendar")
            }
        }
        .popover(isPresented: $showingCalendar, arrowEdge: .bottom) {
            CalendarView(
                provider: viewModel,
                displayMode: .enableWithEntry // Disables days without log files
            )
        }
        Button {
            viewModel.goToToday()
        } label: {
            GoToTodayIcon().offset(x:0 , y: 2)
        }
        .help("Go to Today")
        // Disable the button if the currently selected date is already today.
        .disabled(Calendar.current.isDateInToday(viewModel.selectedDate))
        
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
            Task { await viewModel.generateAndExportReport() }
        } label: {
            Image(systemName: "square.and.arrow.up")
            Text("Export")
        }
        .disabled(viewModel.isLoading || viewModel.checklist == nil)
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
        .frame(width: 600, height: 700)
}
