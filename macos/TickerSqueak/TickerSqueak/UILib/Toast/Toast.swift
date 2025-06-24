//
//  Toast.swift
//  ArctopCentral
//
//  Created by Shai Kalev on 11/5/24.
//


struct Toast: Equatable {
    var style: ToastStyle
    var message: String
    var duration: Double = 3
    var width: Double = .infinity
    var sound:String
}
