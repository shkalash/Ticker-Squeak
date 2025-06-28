//
//  ToastPresenter.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/28/25.
//
import SwiftUI
import Combine

/// A ViewModifier that observes the ToastManager and presents a ToastView when appropriate.
struct ToastPresenter: ViewModifier {
    @ObservedObject private var toastManager = ToastManager.shared

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content // The main app content

            // If a toast is active, display it.
            if let toast = toastManager.currentToast {
                ToastView(toast: toast)
                    // Animate the toast sliding in from the top.
                    .transition(.slide)
                    // Tapping the toast will dismiss it immediately.
                    .onTapGesture {
                        toastManager.dismissCurrentToast()
                    }
            }
        }
    }
}

extension View {
    /// Attaches the toast presentation system to this view.
    func withToasts() -> some View {
        self.modifier(ToastPresenter())
    }
}
