//
//  Dialog.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//
import Foundation
import SwiftUI

// MARK: - 1. The Pure Data Models

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









// MARK: - 4. How to Use (Crucial Step)

/*
 
 IN YOUR MAIN `ContentView` or root view, YOU MUST ATTACH THE `.sheet` MODIFIER.
 This is the missing link that tells your UI to listen to the DialogManager.
 
 Add this to your root view, likely right next to your `.environmentObject` modifier.

 struct ContentView: View {
     // Get the DialogManager from the environment
     @EnvironmentObject private var dialogManager: DialogManager

     var body: some View {
         MyMainAppLayout() // This is your existing view hierarchy
             .sheet(item: $dialogManager.currentDialog) { dialogInfo in
                 DialogView(dialogInfo: dialogInfo)
             }
     }
 }

 And in your main App file:
 
 @main
 struct TickerSqueakApp: App {
     // Create a single instance of the DialogManager
     @StateObject private var dialogManager = DialogManager.shared
     private let dependencies = DependencyContainer()
     
     var body: some Scene {
         WindowGroup {
             ContentView()
                 .environmentObject(dependencies)
                 // Make the DialogManager available to the ContentView
                 .environmentObject(dialogManager)
         }
     }
 }

*/
