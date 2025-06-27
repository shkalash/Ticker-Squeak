import SwiftUI

/// The main internal view of the application. It assembles the primary views for each tab
/// by receiving the dependencies it needs to pass down.
struct ContentView_Content: View {
    
    @StateObject private var viewModel = ContentViewModel()
    
    // It accepts any object conforming to AppDependencies, making it flexible for previews.
    private let dependencies: any AppDependencies

    init(dependencies: any AppDependencies) {
        self.dependencies = dependencies
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main navigation tab picker
            IconTabPicker(selection: $viewModel.selectedTab, options: [
                PickerOption(label: "Tickers", imageName: "chart.bar", tag: 0),
                PickerOption(label: "Hidden List", imageName: "timer", tag: 1),
                PickerOption(label: "Snooze List", imageName: "moon.zzz", tag: 2),
                PickerOption(label: "Ignore List", imageName: "eye.slash", tag: 3),
                PickerOption(label: "Settings", imageName: "gearshape", tag: 4),
            ])
            .padding([.horizontal, .top])
            .padding(.bottom, 8)
            
            Divider()

            // Switch between the main views based on the selected tab.
            // It now calls the _Content versions of its children, passing dependencies explicitly.
            switch viewModel.selectedTab {
            case 0:
                TickerListView_Content(dependencies: dependencies, onSymbolClicked: { ticker in
                    // The charting service is now correctly sourced from the dependency container.
                    //dependencies.chartingService.open(ticker: ticker)
                })
            case 1:
                HiddenTickersView_Content(dependencies: dependencies)
            case 2:
                SnoozeListView_Content(dependencies: dependencies)
            case 3:
                    IgnoreListView_Content(dependencies: dependencies)
            case 4:
                    SettingsView_Content(dependencies: dependencies)
            default:
                EmptyView()
            }
        }
    }
}


/// The public-facing "loader" view for use in the live application.
struct ContentView: View {
    // It reads the REAL DependencyContainer from the environment.
    @EnvironmentObject private var dependencies: DependencyContainer

    var body: some View {
        // It then passes those dependencies into the content view.
        ContentView_Content(dependencies: dependencies)
    }
}
//    var body: some View {
//        VStack {
//            VStack{
//                IconTabPicker(selection: $selectedTab, options: [
//                    PickerOption(label: "Tickers", imageName: "chart.bar", tag: 0),
//                    PickerOption(label: "Ignore", imageName: "eye.slash", tag: 1),
//                    PickerOption(label: "Settings", imageName: "gearshape", tag: 2),
//                ])
//            }.padding(.vertical)
//            switch selectedTab {
//                case 0:
//                    TickerListView(viewModel: viewModel){ ticker in
//                        oneOptionViewModel.openChartInOneOptionApp(ticker: ticker)
//                        tvSettingsViewModel.showTickerInTradingView(ticker)
//                    }
//                case 1:
//                    IgnoreListView(
//                        viewModel: viewModel,
//                        showIgnoreInput: $showIgnoreInput,
//                        ignoreInputText: $ignoreInputText
//                    )
//                case 2:
//                    SettingsView(viewModel: viewModel, tvSettingsViewModel: tvSettingsViewModel, oneOptionViewModel: oneOptionViewModel)
//                default:
//                    Text("Unknown")
//            }
//
//            
//        }
//        .toastView(toast: $viewModel.toastMessage)
//        .sheet(isPresented: $showIgnoreInput) {
//            IgnoreInputSheet(
//                ignoreInputText: $ignoreInputText,
//                showIgnoreInput: $showIgnoreInput,
//                onAddTickers: { tickers in
//                    for sym in tickers {
//                        viewModel.addToIgnore(sym)
//                    }
//                }
//            )
//        }
//    }
//#Preview {
//    ContentView(viewModel: TickerSqueakViewModel(), tvSettingsViewModel: TVViewModel() , oneOptionViewModel: OneOptionViewModel())
//}
#Preview {
    // 1. Create the mock dependency container for the preview.
    let previewDependencies = PreviewDependencyContainer()
    
    // 2. Directly create `ContentView_Content` and pass the mock dependencies
    //    into its initializer. This makes the preview work correctly.
    return ContentView_Content(dependencies: previewDependencies)
        // 3. Still provide the environmentObject for any potential grandchild views.
        .environmentObject(previewDependencies)
        .frame(width: 600, height: 700)
}
