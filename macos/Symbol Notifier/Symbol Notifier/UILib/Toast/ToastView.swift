//
//  ToastView.swift
//  ArctopCentral
//
//  Created by Shai Kalev on 11/5/24.
//


import SwiftUI

struct ToastView: View {
  
  var style: ToastStyle
  var message: String
  var width = CGFloat.infinity
  var onCancelTapped: (() -> Void)
  
  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Image(systemName: style.iconFileName)
        .foregroundColor(style.themeColor)
      Text(message)
        .font(Font.caption)
      Spacer(minLength: 10)
      
      Button {
        onCancelTapped()
      } label: {
        Image(systemName: "xmark")
      }
      .buttonStyle(BorderlessButtonStyle())
    }
    .padding()
    .frame(minWidth: 0, maxWidth: width)
    .frame(height: 28)
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .opacity(0.1)
    )
    .padding(.horizontal, 8)
  }
}
