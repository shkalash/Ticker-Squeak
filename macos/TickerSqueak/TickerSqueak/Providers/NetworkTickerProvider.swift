//
//  SwifterTickerReceiver.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//
import Foundation
import Combine
import Swifter
/// A TickerProvider that runs a local HTTP server to listen for ticker notifications.
class NetworkTickerProvider: TickerProviding {

    // MARK: - Protocol Conformance
    var payloadPublisher = PassthroughSubject<TickerPayload, Never>()
    var isRunningPublisher = CurrentValueSubject<Bool, Never>(false)
    
    // MARK: - Private Properties
    private let server = HttpServer()
    private let settingsManager: SettingsManaging
    private let jsonDecoder = JSONDecoder()
    private var cancellables = Set<AnyCancellable>()

    init(settingsManager: SettingsManaging) {
        self.settingsManager = settingsManager
        
        // This is the reactive configuration logic.
        // The provider now listens for changes to its configuration
        // and automatically handles restarts.
        settingsManager.settingsPublisher
            .map(\.serverPort) // We only care about the port number
            .removeDuplicates() // Ignore changes if the port is the same
            .sink { [weak self] _ in
                // If the server is already running, a port change will trigger a restart.
                if self?.isRunningPublisher.value == true {
                    self?.restartServer()
                }
            }
            .store(in: &cancellables)
    }

    func start() {
        guard !isRunningPublisher.value else { return }
        
        server["/notify"] = { [weak self] request in
            guard let self = self else { return .internalServerError }
            
            let bodyData = Data(request.body)
            do {
                let payload = try self.jsonDecoder.decode(TickerPayload.self, from: bodyData)
                
                // Dispatch to main thread for subscribers
                DispatchQueue.main.async {
                    self.payloadPublisher.send(payload)
                }
                return .ok(.text("OK"))
            } catch {
                let errorMessage = "[Server] Failed to decode TickerPayload: \(error)"
                print(errorMessage)
                // You could report this to your ErrorManager
                return .badRequest(.text("Invalid JSON format"))
            }
        }

        do {
            let port = UInt16(settingsManager.currentSettings.serverPort)
            try server.start(port, forceIPv4: true)
            isRunningPublisher.send(true)
#if DEBUG
            print("[Server] Running on port \(port)")
#endif

        } catch {
            let errorMessage = "[Server] Failed to start: \(error.localizedDescription)"
            print(errorMessage)
            isRunningPublisher.send(false)
            ErrorManager.shared.report(AppError.networkError(description: errorMessage))
        }
    }

    func stop() {
        guard isRunningPublisher.value else { return }
        server.stop()
        isRunningPublisher.send(false)
#if DEBUG
        print("[Server] Stopped.")
#endif
    }
    
    /// A private helper to handle restarting the server, for instance when the port changes.
    private func restartServer() {
#if DEBUG
        print("[Server] Configuration changed. Restarting server...")
#endif
        stop()
        // Add a small delay to ensure the port is fully released before starting again.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.start()
        }
    }
}
