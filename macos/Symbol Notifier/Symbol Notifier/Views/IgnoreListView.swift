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
               
                Button(action : {
                    showIgnoreInput = true
                }, label: {
                    Image(systemName: "plus.square.on.square")
                })
                
                Spacer()
                Button(action : {
                    viewModel.clearIgnoreList()
                }, label: {
                    Image(systemName: "trash")
                })
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
#Preview {
    IgnoreListView(viewModel: SymbolNotifierViewModel(), showIgnoreInput: .constant(false), ignoreInputText: .constant(""))
}
