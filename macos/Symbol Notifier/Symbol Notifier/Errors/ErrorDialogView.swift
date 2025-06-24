//
//  ErrorDialogView.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/24/25.
//


import SwiftUI

/// A view that presents a modal dialog when an error is available from the ErrorManager.
struct ErrorDialogView: View {
    
    /// The error to be displayed. This comes from the ErrorManager.
    let error: Error
    
    /// The action to perform when the dismiss button is tapped.
    let dismissAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Icon to visually represent an error.
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)

            // The main error title.
            Text("An Error Occurred")
                .font(.title2)
                .fontWeight(.bold)

            // The detailed, user-friendly error description.
            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            // Button to dismiss the dialog.
            Button("Dismiss") {
                dismissAction()
            }
            .keyboardShortcut(.defaultAction) // Allows pressing Enter to dismiss.
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 10)
        .frame(maxWidth: 400)
    }
}
