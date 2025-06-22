//
//  View.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/22/25.
//


import SwiftUI
extension View {
    func toastView(toast: Binding<Toast?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}
