//
//  FloatingWebView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/1/25.
//


// FloatingWebView.swift
import SwiftUI

struct FloatingWebView: View {
    // The specific URL you want to load.
    private let targetURL = URL(string: "https://app.oneoption.com/option-stalker/chart/SPY?size=5m")!

    var body: some View {
        StaticWebView(url: targetURL)
            // It's good practice to set a default size for the new window.
            .frame(minWidth: 400, minHeight: 300)
            .alwaysOnTop()
    }
}
