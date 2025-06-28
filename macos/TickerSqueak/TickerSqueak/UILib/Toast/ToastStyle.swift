//
//  ToastStyle.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/28/25.
//

import SwiftUI

extension ToastStyle {
    var iconName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        case .success: return "checkmark.circle.fill"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .info: return Color.blue
        case .warning: return Color.orange
        case .error: return Color.red
        case .success: return Color.green
        }
    }
}
