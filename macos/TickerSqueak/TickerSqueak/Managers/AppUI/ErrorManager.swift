//
//  ErrorManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/24/25.
//


import Foundation
/// A pure translator. Its only job is to convert a Swift `Error` into a `DialogInformation` data packet.
class ErrorManager {
    static let shared = ErrorManager()
    private init() {}

    /// Reports an error, optionally with actions proposed by the caller.
    func report(_ error: Error, proposing actions: [DialogAction] = [] , level: DialogInformation.Level = .error) {
        #if DEBUG
        print("Error Reported: \(error.localizedDescription)")
        #endif
        
        let dialogInfo = DialogInformation(
            title: level == .error ? "Error" : "Warning",
            message: error.localizedDescription,
            level: level,
            actions: actions
        )
        
        DispatchQueue.main.async {
            DialogManager.shared.present(dialogInfo)
        }
    }
    
}
