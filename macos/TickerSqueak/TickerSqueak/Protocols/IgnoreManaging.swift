//
//  IgnoreManaging.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Foundation
import Combine

protocol IgnoreManaging {
    var ignoreList: AnyPublisher<[String], Never> { get }
    
    func addToIgnoreList(_ ticker: String)
    func removeFromIgnoreList(_ ticker: String)
    func clearIgnoreList()
}
