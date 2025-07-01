import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    // 1. Use a @Binding to create a two-way connection to the URL in our ViewModel.
    @Binding var url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        // The coordinator will act as the navigation delegate.
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Only load a new request if the URL has actually changed.
        // This prevents an infinite loop of reloads.
        if nsView.url != url {
            let request = URLRequest(url: url)
            nsView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // The Coordinator acts as a bridge for delegate callbacks.
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }
        
        // 2. When navigation completes, update the binding.
        // This is how user clicks inside the webview update our app's state.
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let newURL = webView.url {
                // Update the parent's @Binding variable.
                parent.url = newURL
            }
        }
    }
}
