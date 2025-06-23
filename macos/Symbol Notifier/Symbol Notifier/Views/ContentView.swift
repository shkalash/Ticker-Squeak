import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: SymbolNotifierViewModel
    @ObservedObject var tvSettingsViewModel: TVViewModel
    @ObservedObject var oneOptionViewModel: OneOptionViewModel
    @State private var selectedTab = 0
    @State private var showIgnoreInput = false
    @State private var ignoreInputText = ""
   
    var body: some View {
        VStack {
            VStack{
                IconTabPicker(selection: $selectedTab, options: [
                    PickerOption(label: "Symbols", imageName: "chart.bar", tag: 0),
                    PickerOption(label: "Ignore", imageName: "eye.slash", tag: 1),
                    PickerOption(label: "Settings", imageName: "gearshape", tag: 2),
                ])
            }.padding(.vertical)
            switch selectedTab {
                case 0:
                    SymbolListView(viewModel: viewModel){ symbol in
                        oneOptionViewModel.openChartInOneOptionApp(symbol: symbol)
                        tvSettingsViewModel.showSymbolInTradingView(symbol)
                    }
                case 1:
                    IgnoreListView(
                        viewModel: viewModel,
                        showIgnoreInput: $showIgnoreInput,
                        ignoreInputText: $ignoreInputText
                    )
                case 2:
                    SettingsView(viewModel: viewModel, tvSettingsViewModel: tvSettingsViewModel, oneOptionViewModel: oneOptionViewModel)
                default:
                    Text("Unknown")
            }

            
        }
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
    ContentView(viewModel: SymbolNotifierViewModel(), tvSettingsViewModel: TVViewModel() , oneOptionViewModel: OneOptionViewModel())
}
