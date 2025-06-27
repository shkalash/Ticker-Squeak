//
//  Dialog.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//
import Foundation
/// Describes the semantic purpose of a dialog action, not its visual style.
enum DialogActionKind {
    case primary      // The main, recommended action (e.g., "Retry", "Save").
    case secondary    // An alternative action.
    case destructive  // An action that is hard to undo (e.g., "Delete", "Abort").
    case cancel       // An action that dismisses the dialog without performing a task.
}

/// A pure data model representing a single, user-performable action.
/// It contains no UI code or presentation logic.
struct DialogAction {
    let title: String
    let kind: DialogActionKind
    let action: () -> Void
}

/// A pure data model representing the complete information needed for a dialog.
struct DialogInformation: Identifiable {
    enum Level { case error, warning, info }
    
    let id = UUID()
    let title: String
    let message: String
    let level: Level
    let actions: [DialogAction]
}
