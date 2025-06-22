//
//  IconTabPicker.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/22/25.
//
import SwiftUI

struct IconTabPicker: View {
    @Binding var selection: Int

    var options: [(label: String, icon: String, tag: Int)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.tag) { option in
                Button(action: {
                    selection = option.tag
                }) {
                    Label(option.label, systemImage: option.icon)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .contentShape(Rectangle()) // Ensures whole area is clickable
                }
                //.padding(4)
                .background(selection == option.tag ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(8)
                .buttonStyle(.plain)
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

}
