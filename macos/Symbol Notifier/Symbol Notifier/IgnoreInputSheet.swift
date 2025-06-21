//
//  IgnoreInputSheet.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/21/25.
//


import SwiftUI

struct IgnoreInputSheet: View {
    @Binding var ignoreInputText: String
    @Binding var showIgnoreInput: Bool
    var onAddSymbols: ([String]) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter symbols to ignore (separate by space or newline)")
                .font(.headline)

            TextEditor(text: $ignoreInputText)
                .frame(minHeight: 150)
                .padding()

            HStack {
                Spacer()
                Button("Cancel") {
                    showIgnoreInput = false
                    ignoreInputText = ""
                }

                Button("Add") {
                    let symbols = ignoreInputText
                        .components(separatedBy: CharacterSet.whitespacesAndNewlines)
                        .filter { !$0.isEmpty }

                    onAddSymbols(symbols)

                    showIgnoreInput = false
                    ignoreInputText = ""
                }.disabled(ignoreInputText.isEmpty)
            }
            .padding()
        }
        .padding()
    }
}
