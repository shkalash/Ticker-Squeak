//
//  ErrorManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/24/25.
//


import Foundation
/// A singleton, observable object to manage and display errors from anywhere in the app.
//class ErrorManager: ObservableObject {
//    
//    /// The shared instance, making it accessible globally.
//    static let shared = ErrorManager()
//    
//    /// A queue to hold errors waiting to be displayed.
//    private var errorQueue: [Error] = []
//    
//    /// The error currently being displayed to the user. The UI will observe this property.
//    @Published var currentError: Error?
//
//    private init() {} // Private initializer to enforce singleton pattern.
//
//    /// The main entry point for reporting an error from anywhere in the app.
//    ///
//    /// It logs the error details in debug builds and adds the error to the queue for presentation.
//    /// - Parameters:
//    ///   - error: The error that occurred.
//    ///   - file: The file where the error was reported (automatically captured).
//    ///   - function: The function where the error was reported (automatically captured).
//    ///   - line: The line number where the error was reported (automatically captured).
//    func report(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
//        // Use the main thread to ensure thread-safe access to the queue.
//        DispatchQueue.main.async {
//            #if DEBUG
//            // In debug mode, print detailed information to the console.
//            let fileName = (file as NSString).lastPathComponent
//            print("--- ‼️ ERROR REPORTED ---")
//            print("  File: \(fileName)")
//            print("  Function: \(function)")
//            print("  Line: \(line)")
//            print("  Error: \(error.localizedDescription)")
//            print("--------------------------")
//            
//            if let appError = error as? AppError {
//                switch appError {
//                    case .developementError: return
//                    default: break
//                }
//            }
//            #endif
//            
//            // Add the new error to the queue.
//            self.errorQueue.append(error)
//            
//            // If no other error is currently being shown, display the next one.
//            if self.currentError == nil {
//                self.showNextError()
//            }
//        }
//    }
//
//    /// Dismisses the currently displayed error and attempts to show the next one in the queue.
//    func dismissCurrentError() {
//        DispatchQueue.main.async {
//            self.currentError = nil
//            // Short delay to allow the dismiss animation to complete before showing the next error.
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                self.showNextError()
//            }
//        }
//    }
//    
//    /// De-queues the next error and sets it as the `currentError` to be displayed.
//    private func showNextError() {
//        guard !errorQueue.isEmpty else {
//            // No more errors to show.
//            return
//        }
//        // Get the next error from the front of the queue.
//        currentError = errorQueue.removeFirst()
//    }
//}
class ErrorManager {
    static let shared = ErrorManager()
    private init() {}

    /// Reports an error, optionally with actions proposed by the caller.
    /// - Parameters:
    ///   - error: The error that occurred.
    ///   - proposing: An array of semantic actions the user can take, provided by the code that caught the error.
    func report(_ error: Error, proposing actions: [DialogAction] = []) {
#if DEBUG
        print("--- ‼️ ERROR REPORTED ---")
        print("Error Reported: \(error.localizedDescription)")
        print("--------------------------")
        // No need to show these errors in the UI, those are for me in the console
        if let appError = error as? AppError {
            switch appError {
                case .developementError: return
                default: break
            }
        }
#endif
        // Create the pure data packet.
        let dialogInfo = DialogInformation(
            title: "Error", // This could be enhanced to be derived from the error type.
            message: error.localizedDescription,
            level: .error,
            actions: actions // Pass the actions through without modification.
        )
        
        // Send the data packet to the presentation queue.
        DispatchQueue.main.async {
            DialogManager.shared.present(dialogInfo)
        }
    }
}
