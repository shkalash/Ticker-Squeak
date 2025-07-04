//
//  StatusButton.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//

import SwiftUI
/// A specific button for displaying and changing a `TradeIdea.IdeaStatus`.
/// It is also built on top of the generic `MultiClickButton`.
struct StatusButton: View {
    let status: IdeaStatus
    
    // Actions for each specific state change.
    let onSetTaken: () -> Void
    let onSetRejected: () -> Void
    let onSetIdea: () -> Void
    
    var body: some View {
        MultiClickButton(
            content: { iconView },
            onLeftClick: onSetTaken,     // Left-click -> Taken
            onRightClick: onSetRejected, // Right-click -> Rejected
            onMiddleClick: onSetIdea     // Middle-click -> Idea (reset)
        )
        .frame(width: 20, height: 20)
    }
    
    @ViewBuilder
    private var iconView: some View {
        Circle()
            .foregroundColor(statusColor)
            .frame(width: 15 , height: 15)
    }
    
    private var statusColor: Color {
        switch status {
            case .idea: .gray
            case .taken: .green
            case .rejected: .red
        }
    }
}
