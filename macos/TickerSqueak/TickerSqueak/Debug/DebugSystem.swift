import SwiftUI

#if DEBUG // Ensure this entire system is only available in Debug builds

// MARK: - Debug View and ViewModel

/// The ViewModel for the DebugView. It now manages the presentation state
/// and queues up actions to be performed after the view is dismissed.
@MainActor
class DebugViewModel: ObservableObject {
    @Published var isPresented = false
    
    /// A closure that holds the action to be performed after the sheet is dismissed.
    private var pendingAction: (() -> Void)?
    
    /// Called by the buttons in the DebugView. It stores the action and dismisses the sheet.
    func performAfterDismissing(action: @escaping () -> Void) {
        self.pendingAction = action
        self.isPresented = false
    }
    
    /// Executes the pending action. This is called from the sheet's `onDismiss` callback.
    func executePendingAction() {
        guard let action = pendingAction else { return }
        
        // Dispatching after a very short delay ensures the dismiss transaction is fully complete.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            action()
        }
        
        // Clear the action so it doesn't run again.
        self.pendingAction = nil
    }
}

/// The UI for the debug panel, containing buttons to trigger various test scenarios.
struct DebugView: View {
    
    // The view now receives all its dependencies explicitly.
    private let dependencies: any AppDependencies
    
    // It gets the ViewModel from its parent to coordinate dismissal.
    @ObservedObject private var viewModel: DebugViewModel
    @State private var tickerToSend: String = "TEST_A"
    init(dependencies: any AppDependencies, viewModel: DebugViewModel) {
        self.dependencies = dependencies
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Debug Panel")
                .font(.title)
                .fontWeight(.bold)
            
            Divider()
            
            Text("Dialog Tests").font(.headline)
            
            // The buttons now call the ViewModel to queue the action.
            Button("Trigger Simple Error Dialog") {
                viewModel.performAfterDismissing {
                    let error = NSError(domain: "TestError", code: 101, userInfo: [NSLocalizedDescriptionKey: "This is a simple test error from the debug panel."])
                    ErrorManager.shared.report(error)
                }
            }
            
            Button("Trigger Error with Retry Action") {
                viewModel.performAfterDismissing {
                    let error = NSError(domain: "TestError", code: 102, userInfo: [NSLocalizedDescriptionKey: "A recoverable error occurred. Please try again."])
                    let retryAction = DialogAction(title: "Retry", kind: .primary) { print("[Debug] Retry action executed!") }
                    ErrorManager.shared.report(error, proposing: [retryAction])
                }
            }
            
            Button("Trigger Informational Dialog") {
                viewModel.performAfterDismissing {
                    let infoDialog = DialogInformation(
                        title: "System Update",
                        message: "A new version of the app is available for download.",
                        level: .info,
                        actions: [DialogAction(title: "OK", kind: .cancel, action: {})]
                    )
                    DialogManager.shared.present(infoDialog)
                }
            }
            
            Divider()
            
            Text("Ticker Provider Tests").font(.headline)
            
            TextField("Test Ticker", text: $tickerToSend)
            
            Button("Simulate High-Priority Ticker") {
                viewModel.performAfterDismissing {
                    let payload = TickerPayload(ticker: tickerToSend, isHighPriority: true)
                    dependencies.tickerProvider.payloadPublisher.send(payload)
                }
            }
            
            Button("Simulate Normal Ticker") {
                viewModel.performAfterDismissing {
                    let payload = TickerPayload(ticker: tickerToSend, isHighPriority: false)
                    dependencies.tickerProvider.payloadPublisher.send(payload)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 400)
    }
}


// MARK: - View Modifier

/// The ViewModifier that attaches the debug functionality as an overlay.
private struct DebugOverlayModifier: ViewModifier {
    
    @StateObject private var viewModel = DebugViewModel()
    
    // It gets the dependencies from the environment to pass to the sheet.
    @EnvironmentObject private var dependencies: DependencyContainer
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottomTrailing) {
            content // The original view content
            
            // Debug button to present the sheet
            Button(action: { viewModel.isPresented.toggle() }) {
                Image(systemName: "ladybug.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            .padding()
            .buttonStyle(.plain)
            .sheet(isPresented: $viewModel.isPresented, onDismiss: {
                // This is the key: onDismiss runs after the sheet is gone.
                // We can now safely execute the queued action.
                viewModel.executePendingAction()
            }) {
                // Pass the dependencies and the ViewModel into the DebugView.
                DebugView(dependencies: dependencies, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Convenience Extension

extension View {
    /// Attaches a debug overlay to the view.
    /// The overlay is only compiled in Debug builds.
    func withDebugOverlay() -> some View {
        self.modifier(DebugOverlayModifier())
    }
}

#endif // End of DEBUG-only code
