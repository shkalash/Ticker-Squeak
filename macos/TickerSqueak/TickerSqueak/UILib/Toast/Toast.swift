//
//  Toast.swift
//  ArctopCentral
//
//  Created by Shai Kalev on 11/5/24.
//

import Foundation

enum ToastStyle {
  case error
  case warning
  case success
  case info
}


struct Toast: Equatable , Identifiable{
    var id = UUID()
    var style: ToastStyle
    var message: String
    var duration: Double = 3
    var width: Double = .infinity
    var sound:String
}
