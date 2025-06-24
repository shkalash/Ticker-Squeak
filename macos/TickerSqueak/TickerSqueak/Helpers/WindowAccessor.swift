//
//  WindowAccessor.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/21/25.
//


import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow) -> ()

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
