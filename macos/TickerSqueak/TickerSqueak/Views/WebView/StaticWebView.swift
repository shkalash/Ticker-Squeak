//
//  WebView 2.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/1/25.
//


// StaticWebView.swift
import SwiftUI
import WebKit

struct StaticWebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
