//
//  IgnoreListView.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/21/25.
//


import SwiftUI

struct IgnoreListView: View {
    @ObservedObject var viewModel: SymbolNotifierViewModel
    @Binding var showIgnoreInput: Bool
    @Binding var ignoreInputText: String

    var body: some View {
        VStack {
            HStack {
                Button("Add Symbols") {
                    showIgnoreInput = true
                }
                Spacer()
                Button("Clear Ignore List") {
                    viewModel.clearIgnoreList()
                }
            }
            .padding([.leading, .trailing, .top])

            List {
                ForEach(viewModel.ignoreList, id: \.self) { symbol in
                    HStack {
                        Text(symbol)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button(action: {
                            viewModel.removeFromIgnore(symbol)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
        }
    }
}
