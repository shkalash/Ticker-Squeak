//
//  RemovalDelayEditorView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/24/25.
//


import SwiftUI
import Combine

/// A reusable view component for editing the ticker removal cooldown time.
struct RemovalDelayEditorView: View {
    
    /// A binding to the TimeInterval property in the ViewModel, which stores the value in seconds.
    @Binding var removalDelay: TimeInterval

    /// A private computed property that creates a custom binding.
    /// This binding converts the TimeInterval (seconds) into a String (minutes) for the TextField,
    /// and handles converting the user's input back into seconds.
    private var minutesBinding: Binding<String> {
        Binding<String>(
            get: {
                // Convert the stored seconds into a whole number of minutes for display.
                "\(Int(self.removalDelay / 60))"
            },
            set: {
                // When the user types a new value, convert it from a String back to seconds.
                if let minutes = Int($0), minutes >= 0 {
                    // Ensure the value is not negative.
                    self.removalDelay = TimeInterval(minutes * 60)
                }
            }
        )
    }

    var body: some View {
        HStack {
            Text("Hide Ticker Cooldown")
            
            Spacer()
            
            // --- Decrement Button ---
            Button(action: {
                // Decrease by 60 seconds (1 minute), ensuring it doesn't go below zero.
                removalDelay = max(0, removalDelay - 60)
            }) {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
            
            // --- Editable Text Field ---
            TextField("", text: minutesBinding)
                .multilineTextAlignment(.center)
                .frame(width: 40)
                .textFieldStyle(.roundedBorder)
                // Filter input to only allow digits.
                .onReceive(Just(minutesBinding.wrappedValue)) { newValue in
                    let filtered = newValue.filter { "0123456789".contains($0) }
                    if filtered != newValue {
                        self.minutesBinding.wrappedValue = filtered
                    }
                }

            // --- Increment Button ---
            Button(action: {
                // Increase by 60 seconds (1 minute).
                removalDelay += 60
            }) {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.borderless)
            
            Text("minutes")
                .frame(width: 60, alignment: .leading)
        }
    }
}


// MARK: - Preview

#Preview {
    // Create a state variable to simulate the binding for the preview.
    @Previewable @State var previewDelay: TimeInterval = 300 // 5 minutes

    return RemovalDelayEditorView(removalDelay: $previewDelay)
        .padding()
        .frame(width: 350)
}
