//
//  IgnoredTickerModel.swift
//  TickerSqueak
//
//  Created for SwiftData migration
//

import Foundation
import SwiftData

@Model
final class IgnoredTickerModel {
    @Attribute(.unique) var ticker: String
    
    init(ticker: String) {
        self.ticker = ticker
    }
}



