//
//  HiddenTickersView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/27/25.
//


import SwiftUI

// The main, internal view for the hidden tickers list.
struct HiddenTickersView_Content: View {
    
    @StateObject private var viewModel: HiddenTickersViewModel

    init(dependencies: any AppDependencies) {
        _viewModel = StateObject(wrappedValue: HiddenTickersViewModel(dependencies: dependencies))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar for the clear all action
            HStack {
                Spacer()
                Button(role: .destructive) {
                    viewModel.clearAll()
                } label: {
                    Label("Reveal All", systemImage: "timer.square")
                }
                .disabled(viewModel.hiddenTickers.isEmpty)
            }
            .padding()

            // The list of hidden tickers
            List {
                ForEach(viewModel.hiddenTickers, id: \.self) { ticker in
                    HStack {
                        Text(ticker)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button(action: {
                            viewModel.reveal(ticker: ticker)
                        }) {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                                .foregroundColor(.cyan)
                        }
                        .buttonStyle(.borderless)
                        .help("Reveal this ticker immediately")
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .overlay {
                if viewModel.hiddenTickers.isEmpty {
                    Text("No Hidden Tickers")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}


/// The public-facing "loader" view for the hidden tickers list.
struct HiddenTickersView: View {
    @EnvironmentObject private var dependencies: DependencyContainer

    var body: some View {
        HiddenTickersView_Content(dependencies: dependencies)
    }
}


#Preview {
    // We need to update the PreviewDependencyContainer to include a placeholder
    // implementation for the hidden tickers logic.
    let previewDependencies = PreviewDependencyContainer()
    
    return HiddenTickersView_Content(dependencies: previewDependencies)
        .environmentObject(previewDependencies)
        .frame(width: 300, height: 400)
}
