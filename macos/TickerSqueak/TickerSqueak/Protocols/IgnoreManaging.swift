//
//  IgnoreManaging.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Foundation
import Combine
/// Contract for managing the ignored Tickers in the app
protocol IgnoreManaging {
    /// Up to date list
    var ignoreList: AnyPublisher<[String], Never> { get }
    /// List updating 
    func addToIgnoreList(_ ticker: String)
    func removeFromIgnoreList(_ ticker: String)
    func clearIgnoreList()
}
