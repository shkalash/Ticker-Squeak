//
//  ToastManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/27/25.
//
import Foundation
import Combine
import SwiftUI
/// A singleton, observable object that manages the queue and presentation of toasts.
@MainActor
class ToastManager: ObservableObject {
    
    static let shared = ToastManager()
    private init() {}

    /// The toast currently being presented to the user. The UI observes this property.
    @Published var currentToast: Toast?
    
    private var toastQueue: [Toast] = []
    private var dismissTimer: Timer?

    /// The main entry point for showing a toast from anywhere in the app.
    func show(_ toast: Toast) {
        toastQueue.append(toast)
        // If no other toast is currently being shown, display the next one.
        if currentToast == nil {
            showNextToast()
        }
    }

    /// Dismisses the current toast and attempts to show the next one in the queue.
    func dismissCurrentToast() {
        guard currentToast != nil else { return }
        
        dismissTimer?.invalidate()
        withAnimation(.spring()) {
            currentToast = nil
        }
        
        // After the dismiss animation, check for the next toast.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.showNextToast()
        }
    }
    
    private func showNextToast() {
        guard !toastQueue.isEmpty else {
            currentToast = nil
            return
        }
        
        withAnimation(.spring()) {
            currentToast = toastQueue.removeFirst()
        }
        
        if let toastSound = currentToast?.sound{
           Task {
               await SoundManager.shared.playSoundForNotification(named: toastSound, cooldown: 2)
            }
        }
        
        // Set a timer to automatically dismiss this toast after its duration.
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: currentToast!.duration, repeats: false) { _ in
            DispatchQueue.main.async {
                self.dismissCurrentToast()
            }
        }
    }
}
