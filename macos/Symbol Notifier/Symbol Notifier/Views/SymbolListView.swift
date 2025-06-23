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
        viewModel.symbolList.filter { item in
            // Highlight filter
            if viewModel.showHighlightedOnly && !item.isHighlighted {
                return false
            }

            // Direction filters
            switch item.direction {
            case .bullish where !viewModel.showBullish:
                return false
            case .bearish where !viewModel.showBearish:
                return false
            default:
                return true
            }
        }
    }


    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    viewModel.showHighlightedOnly.toggle()
                }) {
                    Image(systemName: viewModel.showHighlightedOnly ? "star.fill" : "star.slash.fill")
                        .foregroundColor(viewModel.showHighlightedOnly ? .yellow : .gray)
                }
                .buttonStyle(.bordered)
                Button(action: {
                    viewModel.showBullish.toggle()
                }) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(viewModel.showBullish ? .green : .gray)
                }
                .buttonStyle(.bordered)
                Button(action: {
                    viewModel.showBearish.toggle()
                }) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .foregroundColor(viewModel.showBearish ? .red : .gray)
                }
                .buttonStyle(.bordered)
                Button(action: {
                    if (!viewModel.showBullish && !viewModel.showBearish){
                        viewModel.showBullish = true
                        viewModel.showBearish = true
                    }
                    else{
                        viewModel.showBullish = false
                        viewModel.showBearish = false
                    }
                    
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Image(systemName: "chart.line.downtrend.xyaxis")
                    }
                }
                .buttonStyle(.bordered)
                .foregroundColor(.primary)
                Button(action: {
                    viewModel.muteNotifications.toggle()
                }) {
                    Image(systemName: viewModel.muteNotifications ?
                          "speaker.slash" : "speaker.wave.3"
                          )
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                Spacer()
                Button(action : {
                    viewModel.clearSymbols()
                }, label: {
                    Image(systemName: "trash")
                })
            }
            .padding([.leading, .trailing, .top])

            List(filteredSymbols) { item in
                HStack {
                    Button(action: {
                        viewModel.toggleHighlight(item)
                    }) {
                        Image(systemName: item.isHighlighted ? "star.fill" : "star.slash.fill")
                            .foregroundColor(item.isHighlighted ? .yellow : .gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    DirectionButton(item: Binding(
                        get: { item },
                        set: { viewModel.updateItem($0) }
                    ))
                    Button(action: {
                        self.onClick(item.symbol)
                    }) {
                        HStack {
                            Text(item.symbol)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(item.isHighlighted ? .primary : .gray)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                    Button(action: {
                        viewModel.hideSymbol(item)
                    }) {
                        Image(systemName: "timer")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Text((item.receivedAt.formatted(date: .omitted, time: .shortened)))
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
#Preview {
    SymbolListView(viewModel: SymbolNotifierViewModel(), onSymobolClicked: { _ in })
}
