//
//  DialogView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import SwiftUI

struct DialogView: View {
    let dialogInfo: DialogInformation
    
    var body: some View {
        VStack(spacing: 20) {
            // UI can use the 'level' to show an appropriate icon.
            Image(systemName: iconName(for: dialogInfo.level))
                .font(.largeTitle)
                .foregroundColor(color(for: dialogInfo.level))

            Text(dialogInfo.title)
                .font(.headline)

            Text(dialogInfo.message)
                .multilineTextAlignment(.center)

            // The UI layer is responsible for rendering the buttons.
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

struct DialogButton: View {
    let action: DialogAction
    
    var body: some View {
        Button(action: {
            // The UI layer wraps the provided action with a call to dismiss the dialog.
            action.action()
            DialogManager.shared.dismissCurrentDialog()
        }) {
            Text(action.title)
                .frame(maxWidth: .infinity)
        }
        .keyboardShortcut(action.kind == .primary ? .defaultAction : .cancelAction)
        .tint(action.kind == .destructive ? .red : .accentColor) // UI renders style based on semantic kind
    }
}


extension View {
    func withDialogs(manager: DialogManager) -> some View {
       
        self.sheet(item: Binding(
            get: { manager.currentDialog },
            set: { if $0 == nil { manager.dismissCurrentDialog() } }
        )) { dialogInfo in
            DialogView(dialogInfo: dialogInfo)
        }
    }
}
