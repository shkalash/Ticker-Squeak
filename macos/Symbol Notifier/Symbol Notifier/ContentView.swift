//
//  ContentView.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/21/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: SymbolNotifierViewModel
    @State private var selectedTab = 0
    @State private var showIgnoreInput = false
    @State private var ignoreInputText = ""

    var filteredSymbols: [SymbolItem] {
        if viewModel.showHighlightedOnly {
            return viewModel.symbolList.filter { $0.isHighlighted }
        } else {
            return viewModel.symbolList
        }
    }

    var body: some View {
        VStack {
            Picker("", selection: $selectedTab) {
                Text("Symbols").tag(0)
                Text("Ignore List").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if selectedTab == 0 {
                symbolListView
            } else {
                ignoreListView
            }

            // Toast
            if let toast = viewModel.toastMessage {
                VStack {
                    Text(toast)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut, value: viewModel.toastMessage)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(width: 350, height: 450)
        .sheet(isPresented: $showIgnoreInput) {
            ignoreInputSheet
        }
    }
    
    var symbolListView: some View {
        VStack {
            // Toolbar
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

            // Symbol List
            List(filteredSymbols) { item in
                HStack {
                    // Highlight toggle icon
                    Button(action: {
                        viewModel.toggleHighlight(item)
                    }) {
                        Image(systemName: item.isHighlighted ? "bell.fill" : "bell.slash.fill")
                            .foregroundColor(item.isHighlighted ? .yellow : .gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    // Symbol copy button (full row up to ignore)
                    Button(action: {
                        copySymbol(item.symbol)
                        viewModel.toggleHighlight(item)
                    }) {
                        HStack {
                            Text(item.symbol)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(item.isHighlighted ? .primary : .gray)
                            Spacer()
                        }
                        .contentShape(Rectangle()) // ensures full HStack is tappable
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Add to ignore list
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



//    var symbolListView: some View {
//        VStack {
//            HStack {
//                Toggle("Only Highlighted", isOn: Binding(
//                    get: { viewModel.showHighlightedOnly },
//                    set: {
//                        viewModel.setShowHighlightedOnly($0)
//                    }
//                ))
//                Spacer()
//                Button("Clear") {
//                    viewModel.clearSymbols()
//                }
//            }
//            .padding([.leading, .trailing, .top])
//
//            List(filteredSymbols) { item in
//                HStack {
//                    if item.isHighlighted {
//                        Button(action: {
//                            viewModel.toggleHighlight(item)
//                        }) {
//                            Image(systemName: "bell.fill")
//                                .foregroundColor(.yellow)
//                        }
//                        .buttonStyle(BorderlessButtonStyle())
//                    } else {
//                        Image(systemName: "bell.slash.fill")
//                            .foregroundColor(.gray)
//                    }
//
//                    Button(action: {
//                        copySymbol(item.symbol)
//                        viewModel.toggleHighlight(item)
//                    }) {
//                        Text(item.symbol)
//                            .font(.system(.body, design: .monospaced))
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//            }
//        }
//    }

    var ignoreListView: some View {
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

    var ignoreInputSheet: some View {
        VStack(spacing: 20) {
            Text("Enter symbols to ignore (separate by space or newline)")
                .font(.headline)
            TextEditor(text: $ignoreInputText)
                .frame(height: 150)
                .border(Color.gray, width: 1)
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

                    for sym in symbols {
                        viewModel.addToIgnore(sym)
                    }

                    showIgnoreInput = false
                    ignoreInputText = ""
                }
            }
            .padding()
        }
        .padding()
        .frame(width: 350, height: 250)
    }

    func copySymbol(_ symbol: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(symbol, forType: .string)
        #endif
    }
}
