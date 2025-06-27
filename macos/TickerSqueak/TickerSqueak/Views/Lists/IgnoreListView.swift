import SwiftUI
import Combine

// The main view for the ignore list. Its initializer requires the dependencies,
// ensuring it cannot be created without them.
struct IgnoreListView_Content: View {
    
    /// The view's dedicated ViewModel. The lifecycle is tied to this view.
    @StateObject private var viewModel: IgnoreListViewModel
    
    /// Local state to control the presentation of the input sheet.
    @State private var isShowingInputSheet = false

    init(dependencies: any AppDependencies) {
        // Correctly initialize the @StateObject once when the view is created.
        _viewModel = StateObject(wrappedValue: IgnoreListViewModel(dependencies: dependencies))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar for adding and clearing items
            HStack {
                Button {
                    isShowingInputSheet = true
                } label: {
                    Image(systemName: "plus.square.on.square")
                    Text("Add")
                }
                
                Spacer()
                
                Button(role: .destructive) {
                    viewModel.clearAll()
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(viewModel.ignoreList.isEmpty)
            }
            .padding()
            
            // The list of ignored tickers
            List {
                ForEach(viewModel.ignoreList, id: \.self) { ticker in
                    HStack {
                        Text(ticker)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button(action: {
                            viewModel.remove(ticker: ticker)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless) 
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .sheet(isPresented: $isShowingInputSheet) {
            // Present the input sheet when the state variable is true
            IgnoreInputSheet(onAddTickers: { tickersToAdd in
                viewModel.add(tickers: tickersToAdd)
            })
        }
    }
}


/// The public-facing "loader" view.
/// Its only job is to fetch the dependencies from the SwiftUI environment
/// and pass them to the actual content view. Parent views should use this.
struct IgnoreListView: View {
    @EnvironmentObject private var dependencies: DependencyContainer

    var body: some View {
        // Pass the resolved dependencies to the content view's initializer.
        IgnoreListView_Content(dependencies: dependencies)
    }
}


#Preview {
    // The preview now creates the dependency container and injects it into the environment.
    let previewDependencies = PreviewDependencyContainer()
    
    // We call the public-facing IgnoreListView(), which pulls from the environment.
    IgnoreListView_Content(dependencies: previewDependencies)
        .frame(width: 300, height: 400)
}
