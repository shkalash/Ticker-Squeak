//
//  SnoozeListView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/27/25.
//


import SwiftUI

// The main, internal view for the snooze list.
struct SnoozeListView_Content: View {
    
    @StateObject private var viewModel: SnoozeListViewModel

    init(dependencies: any AppDependencies) {
        _viewModel = StateObject(wrappedValue: SnoozeListViewModel(dependencies: dependencies))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar for the clear all action
            HStack {
                Spacer()
                Button(role: .destructive) {
                    viewModel.clearAll()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(viewModel.snoozedTickers.isEmpty)
            }
            .padding()

            // The list of snoozed tickers
            List {
                ForEach(viewModel.snoozedTickers, id: \.self) { ticker in
                    HStack {
                        Text(ticker)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button(action: {
                            viewModel.remove(ticker: ticker)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .overlay {
                if viewModel.snoozedTickers.isEmpty {
                    Text("No Snoozed Tickers")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}


/// The public-facing "loader" view for the snooze list.
struct SnoozeListView: View {
    @EnvironmentObject private var dependencies: DependencyContainer

    var body: some View {
        SnoozeListView_Content(dependencies: dependencies)
    }
}


#Preview {
    // The preview creates a mock dependency container that has some
    // default snoozed tickers in its placeholder manager.
    let previewDependencies = PreviewDependencyContainer()
    
    return SnoozeListView_Content(dependencies: previewDependencies)
        .environmentObject(previewDependencies)
        .frame(width: 300, height: 400)
}
