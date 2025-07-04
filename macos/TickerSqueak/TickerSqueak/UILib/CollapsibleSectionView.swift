//
//  CollapsibleSectionView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import SwiftUI

/// A reusable view that displays a title in a tappable header, which expands or
/// collapses to show or hide its content.
struct CollapsibleSectionView<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                isExpanded.toggle()
            }) {
                HStack {
                    Image(systemName: "chevron.right")
                        .font(.caption).fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .padding(.leading, 10)
            }
        }
    }
}
