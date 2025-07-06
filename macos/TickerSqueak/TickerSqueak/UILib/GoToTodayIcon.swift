//
//  GoToTodayIcon.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/6/25.
//


import SwiftUI

/// A custom composite icon that displays a calendar with a "go to today" action badge.
struct GoToTodayIcon: View {
    @Environment(\.isEnabled) private var isEnabled
    var body: some View {
        // The base calendar icon.
        Image(systemName: "calendar")
            .font(.title2) // You can adjust the size of the base icon here
            .overlay(alignment: .bottomTrailing) {
                // The badge is placed in the bottom-right corner.
                ZStack {
                    // A circle behind the badge icon to make it stand out.
                    Circle()
                        .fill(.background) // Use the system background color
                        .frame(width: 8, height: 8)

                    // The u-turn arrow icon for the badge.
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 10))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.black , .white)
                }
                .opacity(isEnabled ? 1.0 : 0.5)
                // Offset the badge slightly to make it overlap the calendar's edge.
                .offset(x: 2, y:1)
            }
            
    }
}

// MARK: - Alternative with "Bullseye" Icon

/// An alternative version using the "target" (bullseye) symbol.
struct GoToTodayTargetIcon: View {
    @Environment(\.isEnabled) private var isEnabled
    var body: some View {
        Image(systemName: "calendar")
            .font(.title2)
            .overlay(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(.background)
                        .frame(width: 8, height: 8)

                    // Use the "target" symbol instead.
                    Image(systemName: "target")
                        .font(.system(size: 10))
                        .foregroundStyle(.white , .white)
                }
                .opacity(isEnabled ? 1.0 : 0.5)
                .offset(x: 2, y: 1)
            }
    }
}


// You can use this preview to fine-tune the icon's appearance.
#Preview {
    HStack(spacing: 30) {
        GoToTodayIcon()
        GoToTodayTargetIcon()
    }
    .font(.largeTitle)
    .padding()
}
