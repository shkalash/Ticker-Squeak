//
//  AppNavigationCoordinating.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation
import Combine

/// Defines a contract for a service that coordinates navigation between different parts of the app.
protocol AppNavigationCoordinating: ObservableObject {
    /// A publisher that emits the ticker for a requested trade idea navigation.
    var tradeIdeaTickerToNavigate: String? { get }
    
    /// Called by a view (like TickerListView) to request navigation to a trade idea.
    func requestNavigation(toTicker ticker: String)
    
    /// Called by the destination view (TradeIdeasListViewModel) after it has handled the request.
    func clearTradeIdeaNavigationRequest()
}
