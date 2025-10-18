//
//  TC2000Settings.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 10/18/25.
//

import Foundation

struct TC2000Settings: Codable, Equatable {
    var isEnabled: Bool
    var host: String
    var port: Int
    static let `default` = TC2000Settings(isEnabled: false, host: "10.211.55.3", port: 5055)
}
