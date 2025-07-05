//
//  ScrollFriendlyTextEditor.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/5/25.
//
import SwiftUI
/// Simple replacement for the text editor allowing to scroll over it in long lists.
/// Become editable on click, allows shift+retrun for new lines, un focuses when return is clicked
struct ScrollFriendlyTextEditor: View {
        @Binding var text: String
        @FocusState private var isFocused: Bool
        
        var body: some View {
            TextEditor(text: $text)
                .font(.body)
                .focused($isFocused)
                .scrollDisabled(!isFocused)
                .onKeyPress { keyPress in
                    if keyPress.key == .return {
                        if keyPress.modifiers.contains(.shift) {
                            return .ignored
                        } else {
                            isFocused = false
                            return .handled
                        }
                    }
                    return .ignored
                }
                .onTapGesture {
                    if !isFocused {
                        isFocused = true
                    }
                }
        }
    }
