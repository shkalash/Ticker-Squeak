//
//  DialogManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Foundation
import SwiftUI
/// The central queue controller. It manages a queue of pure `DialogInformation` data.
@MainActor
class DialogManager: ObservableObject {
    static let shared = DialogManager()
    
    @Published private(set) var currentDialog: DialogInformation?
    private var dialogQueue: [DialogInformation] = []

    private init() {}

    /// Adds a dialog data packet to the queue for presentation.
    func present(_ dialogInfo: DialogInformation) {
        dialogQueue.append(dialogInfo)
        if currentDialog == nil {
            showNextDialog()
        }
    }

    /// Dismisses the currently displayed dialog and attempts to show the next one.
    /// This is called by the UI layer after an action has been performed.
    func dismissCurrentDialog() {
        currentDialog = nil
        // Allow dismiss animation to complete before showing the next dialog.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showNextDialog()
        }
    }
    
    private func showNextDialog() {
        guard !dialogQueue.isEmpty else { return }
        currentDialog = dialogQueue.removeFirst()
    }
}
