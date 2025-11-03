//
//  SnoozedTickerModel.swift
//  TickerSqueak
//
//  Created for SwiftData migration
//

import Foundation
import SwiftData

@Model
final class SnoozedTickerModel {
    @Attribute(.unique) var ticker: String
    
    init(ticker: String) {
        self.ticker = ticker
    }
}



