//
//  SnoozeTimeEditorView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/25/25.
//


import SwiftUI

/// A reusable view component for editing the daily snooze clear time.
struct SnoozeTimeEditorView: View {
    
    /// A binding to the Date property in the ViewModel.
    /// The DatePicker will only modify the time components of this Date.
    @Binding var snoozeClearTime: Date

    var body: some View {
        HStack{
            Text("Clear Snooze List Daily at: ")
            Spacer()
            // A DatePicker is the standard and most user-friendly way to select a time.
            DatePicker(
                selection: $snoozeClearTime,
                displayedComponents: .hourAndMinute // Configure it to only show time controls.
            ){}
                .datePickerStyle(.stepperField)
        }
    }
}
