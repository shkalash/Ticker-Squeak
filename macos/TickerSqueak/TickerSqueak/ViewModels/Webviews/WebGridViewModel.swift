//
//  to.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/28/25.
//


import SwiftUI
import Combine

// 1. A simple struct to hold the state for a single web view instance.
//    It's Identifiable so SwiftUI's ForEach can track it uniquely.
struct WebViewState: Identifiable {
    let id = UUID()
    var url: URL
}

// 2. The ViewModel, which is an ObservableObject so SwiftUI views can subscribe to its changes.
@MainActor // Ensures UI-related updates happen on the main thread.
class WebGridViewModel: ObservableObject {
    
    // The source of truth for all our web views. @Published notifies views of any changes.
    @Published var webViewStates: [WebViewState] = []
    
    // The desired number of web views, clamped between 1 and 8.
    @Published var gridCount: Int = 2 {
        didSet {
            // Clamp the value to our allowed range.
            let clampedCount = max(1, min(8, gridCount))
            if clampedCount != gridCount {
                gridCount = clampedCount
            }
            // Update the grid whenever the count changes.
            adjustWebViewStates()
        }
    }
    
    init() {
        // Initialize with the default grid count.
        adjustWebViewStates()
    }
    
    private func adjustWebViewStates() {
        let difference = gridCount - webViewStates.count
        
        if difference > 0 {
            // If the new count is higher, add new web view states.
            for _ in 0..<difference {
                // You can set a default URL for new views.
                let defaultURL = URL(string: "https://app.oneoption.com/option-stalker/chart/SPY?size=5m")!
                webViewStates.append(WebViewState(url: defaultURL))
            }
        } else if difference < 0 {
            // If the new count is lower, remove states from the end.
            webViewStates.removeLast(abs(difference))
        }
    }
}
