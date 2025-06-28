//
//  DialogView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import SwiftUI
// MARK: - 3. The UI Layer (Dialog View)

// This view is responsible for rendering the `DialogInformation` data packet.
struct DialogView: View {
    let dialogInfo: DialogInformation
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName(for: dialogInfo.level))
                .font(.largeTitle)
                .foregroundColor(color(for: dialogInfo.level))

            Text(dialogInfo.title)
                .font(.headline)

            Text(dialogInfo.message)
                .multilineTextAlignment(.center)

            HStack {
                // UI Layer Rule: If no actions are provided, create a default OK button.
                let actions = dialogInfo.actions.isEmpty ? [defaultDismissAction] : dialogInfo.actions
                
                ForEach(actions.indices, id: \.self) { index in
                    DialogButton(action: actions[index])
                }
            }
        }
        .padding()
        .frame(minWidth: 300)
    }
    
    // A default action used when none are provided by the caller.
    private var defaultDismissAction: DialogAction {
        DialogAction(title: "OK", kind: .cancel, action: {})
    }
    
    private func iconName(for level: DialogInformation.Level) -> String {
        switch level {
        case .error: return "xmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    private func color(for level: DialogInformation.Level) -> Color {
        switch level {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

// A view for a single button within the dialog.
struct DialogButton: View {
    let action: DialogAction
    
    var body: some View {
        Button(action: {
            // First, perform the action's specific logic.
            action.action()
            // Then, tell the manager to dismiss the dialog.
            DialogManager.shared.dismissCurrentDialog()
        }) {
            Text(action.title)
                .frame(maxWidth: .infinity)
        }
        .keyboardShortcut(action.kind == .primary ? .defaultAction : .cancelAction)
        .tint(action.kind == .destructive ? .red : .accentColor)
    }
}
