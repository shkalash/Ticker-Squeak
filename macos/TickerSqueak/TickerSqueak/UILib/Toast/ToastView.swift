//
//  ToastView 2.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/28/25.
//
import SwiftUI


/// A view that displays a single toast message.
struct ToastView: View {
    let toast: Toast
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.style.iconName)
                .font(.title3)
            Text(toast.message)
                .font(.body)
            Spacer(minLength: 0)
        }
        .foregroundColor(.white)
        .padding()
        .background(toast.style.backgroundColor)
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

