import SwiftUI

/// The main internal view of the application.
struct ContentView_Content: View {
    
    @StateObject private var viewModel = ContentViewModel()
    
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

            switch viewModel.selectedTab {
            case 0:
                TickerListView_Content(dependencies: dependencies, onTickerClicked: { ticker in
                    dependencies.chartingService.open(ticker: ticker)
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

    @EnvironmentObject private var dependencies: DependencyContainer
    @EnvironmentObject private var dialogManager: DialogManager

    var body: some View {
        ContentView_Content(dependencies: dependencies)
        .sheet(item: $dialogManager.currentDialog) { dialogInfo in
            DialogView(dialogInfo: dialogInfo)
        }
        .withToasts()
    }
}

#Preview {

    let previewDependencies = PreviewDependencyContainer()
    
    return ContentView_Content(dependencies: previewDependencies)
        .environmentObject(previewDependencies)
        .frame(width: 300, height: 400)
}
