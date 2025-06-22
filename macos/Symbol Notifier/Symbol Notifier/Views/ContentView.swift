import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: SymbolNotifierViewModel
    @ObservedObject var tvSettingsViewModel: TVSettingsViewModel
    @State private var selectedTab = 0
    @State private var showIgnoreInput = false
    @State private var ignoreInputText = ""
   
    var body: some View {
        VStack {
            VStack{
                IconTabPicker(selection: $selectedTab, options: [
                    ("Symbols", "chart.bar", 0),
                    ("Ignore", "eye.slash", 1),
                    ("Settings", "gearshape", 2),
                ])
            }.padding(.vertical)
            switch selectedTab {
                case 0:
                    SymbolListView(viewModel: viewModel){ symbol in
                        tvSettingsViewModel.showSymbolInTradingView(symbol)
                    }
                case 1:
                    IgnoreListView(
                        viewModel: viewModel,
                        showIgnoreInput: $showIgnoreInput,
                        ignoreInputText: $ignoreInputText
                    )
                case 2:
                    SettingsView(viewModel: viewModel, tvSettingsViewModel: tvSettingsViewModel)
                default:
                    Text("Unknown")
            }

            
        }
        .frame(width: 350, height: 450)
        .toastView(toast: $viewModel.toastMessage)
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
#Preview {
    ContentView(viewModel: SymbolNotifierViewModel(), tvSettingsViewModel: TVSettingsViewModel())
}
