//
//  SymbolListView.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/21/25.
//


import SwiftUI

struct SymbolListView: View {
    @ObservedObject var viewModel: SymbolNotifierViewModel
    private let onClick: (String) -> Void

    init(viewModel: SymbolNotifierViewModel , onSymobolClicked: @escaping (String) -> Void) {
        self.onClick = onSymobolClicked
        self.viewModel = viewModel
    }
    
    var filteredSymbols: [SymbolItem] {
        viewModel.showHighlightedOnly
            ? viewModel.symbolList.filter { $0.isHighlighted }
            : viewModel.symbolList
    }

    var body: some View {
        VStack {
            HStack {
                Toggle("Only Highlighted", isOn: Binding(
                    get: { viewModel.showHighlightedOnly },
                    set: { viewModel.setShowHighlightedOnly($0) }
                ))
                Spacer()
                Button("Clear") {
                    viewModel.clearSymbols()
                }
            }
            .padding([.leading, .trailing, .top])

            List(filteredSymbols) { item in
                HStack {
                    Button(action: {
                        viewModel.toggleHighlight(item)
                    }) {
                        Image(systemName: item.isHighlighted ? "bell.fill" : "bell.slash.fill")
                            .foregroundColor(item.isHighlighted ? .yellow : .gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    Button(action: {
                        self.onClick(item.symbol)
                        //copySymbol(item.symbol)
                        //viewModel.toggleHighlight(item)
                    }) {
                        HStack {
                            Text(item.symbol)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(item.isHighlighted ? .primary : .gray)
                            Spacer()
                            Text((item.receivedAt.formatted(date: .omitted, time: .shortened)))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        viewModel.addToIgnore(item.symbol)
                    }) {
                        Image(systemName: "eye.slash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.vertical, 4)
                .listRowBackground(item.isHighlighted ? Color.yellow.opacity(0.2) : Color.clear)
            }
        }
    }

    func copySymbol(_ symbol: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(symbol, forType: .string)
        #endif
    }
}
