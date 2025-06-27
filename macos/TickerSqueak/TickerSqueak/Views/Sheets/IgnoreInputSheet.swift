import SwiftUI

struct IgnoreInputSheet: View {
    /// Local state to hold the text being entered by the user.
    @State private var inputText: String = ""
    
    /// The environment value for dismissing the sheet.
    @Environment(\.dismiss) private var dismiss
    
    /// A closure that is called when the user taps the "Add" button.
    var onAddTickers: ([String]) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter tickers to ignore")
                .font(.headline)
            
            Text("You can separate multiple tickers by spaces or newlines.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextEditor(text: $inputText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 150)
                .border(Color.secondary.opacity(0.5), width: 1)
                .cornerRadius(5)

            HStack {
                // Cancel button simply dismisses the sheet
                Button("Cancel", role: .cancel) {
                    dismiss()
                }

                Spacer()

                // Add button processes the text and calls the closure
                Button("Add Tickers") {
                    let tickers = inputText
                        .components(separatedBy: .whitespacesAndNewlines)
                        .filter { !$0.isEmpty }

                    onAddTickers(tickers)
                    dismiss()
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

#Preview {
    // The preview just shows the sheet and prints the action.
    IgnoreInputSheet(onAddTickers: { tickers in
        print("Tickers to add: \(tickers)")
    })
}
