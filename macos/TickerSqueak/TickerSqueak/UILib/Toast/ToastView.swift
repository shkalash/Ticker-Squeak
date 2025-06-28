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
                .foregroundColor(toast.style.infoColor)
                .font(.title)
            Text(toast.message)
                .font(.body)
            Spacer(minLength: 0)
        }
        .padding()
        .background(.black.opacity(0.85))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(toast.style.infoColor.opacity(0.6), lineWidth: 2)
        )
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding()
    }
}

extension ToastStyle {
    var iconName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        case .success: return "checkmark.circle.fill"
        case .importantInfo: return "exclamationmark.square.fill"
        }
    }
    
    var infoColor: Color {
        switch self {
        case .importantInfo: return Color.teal
        case .info: return Color.blue
        case .warning: return Color.orange
        case .error: return Color.red
        case .success: return Color.green
        }
    }
}


#Preview {
    VStack(spacing: 20){
        ToastView(toast: Toast(style: .info, message: "Toast Info", sound: ""))
        ToastView(toast: Toast(style: .warning, message: "Toast Info", sound: ""))
        ToastView(toast: Toast(style: .error, message: "Toast Info", sound: ""))
        ToastView(toast: Toast(style: .success, message: "Toast Info", sound: ""))
        ToastView(toast: Toast(style: .importantInfo, message: "Toast Info", sound: ""))
    }.padding()
}
