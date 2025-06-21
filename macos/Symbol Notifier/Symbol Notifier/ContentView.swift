import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: SymbolNotifierViewModel
    @State private var selectedTab = 0
    @State private var showIgnoreInput = false
    @State private var ignoreInputText = ""

    var body: some View {
        VStack {
            Picker("", selection: $selectedTab) {
                Text("Symbols").tag(0)
                Text("Ignore List").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if selectedTab == 0 {
                SymbolListView(viewModel: viewModel)
            } else {
                IgnoreListView(
                    viewModel: viewModel,
                    showIgnoreInput: $showIgnoreInput,
                    ignoreInputText: $ignoreInputText
                )
            }

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
            IgnoreInputSheet(
                ignoreInputText: $ignoreInputText,
                showIgnoreInput: $showIgnoreInput,
                onAddSymbols: { symbols in
                    for sym in symbols {
                        viewModel.addToIgnore(sym)
                    }
                }
            )
        }
    }
}
