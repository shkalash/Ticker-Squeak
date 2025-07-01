import SwiftUI

import SwiftUI

struct WebGridView: View {
    @StateObject private var viewModel = WebGridViewModel()

    // MARK: - Computed Properties for Rows
    // These computed properties are the core of the new layout logic.
    // They split the single list from the ViewModel into two separate lists for our rows.

    /// Filters the ViewModel's list to get only the states for the top row (0, 2, 4, etc.).
    private var topRowStates: [Binding<WebViewState>] {
        $viewModel.webViewStates.enumerated()
            .filter { $0.offset % 2 == 0 } // Even indices
            .map { $0.element }
    }
    
    /// Filters the ViewModel's list to get only the states for the bottom row (1, 3, 5, etc.).
    private var bottomRowStates: [Binding<WebViewState>] {
        $viewModel.webViewStates.enumerated()
            .filter { $0.offset % 2 == 1 } // Odd indices
            .map { $0.element }
    }

    var body: some View {
        VStack(spacing: 0) { // Use 0 spacing for a seamless look
            // MARK: - Control Panel (No changes here)
            HStack {
                Text("Number of Views:")
                Slider(value: Binding(
                    get: { Double(viewModel.gridCount) },
                    set: { viewModel.gridCount = Int($0) }
                ), in: 1...8, step: 1)
                Text("\(viewModel.gridCount)")
                    .font(.headline)
                    .frame(width: 30)
            }
            .padding()

            // MARK: - Custom Two-Row Web View Container
            // This VStack will hold our two rows and ensure they divide the available space.
            VStack(spacing: 0) {
                // Only show the top row if it has items.
                //if !topRowStates.isEmpty {
                    // An HStack will automatically divide its width equally among its children.
                    HStack(spacing: 0) {
                        ForEach(topRowStates) { $webViewState in
                            WebView(url: $webViewState.url)
                                .border(Color.gray, width: 0.5) // Add a thin border for clarity
                        }
                    }
                    // This frame modifier makes the HStack flexible, allowing it to take up
                    // either 100% or 50% of the parent VStack's height.
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                //}
                
                // Only show the bottom row if it has items.
                if !bottomRowStates.isEmpty {
                    HStack(spacing: 0) {
                        ForEach(bottomRowStates) { $webViewState in
                            WebView(url: $webViewState.url)
                                .border(Color.gray, width: 0.5)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}
#Preview {
    WebGridView()
        .frame(width: 800 , height: 600)
}
