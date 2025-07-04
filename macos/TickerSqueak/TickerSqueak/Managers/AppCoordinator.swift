//
//  AppCoordinator.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation

/// The concrete implementation of the navigation coordinator.
/// It uses a @Published property to hold the pending navigation request.
class AppCoordinator: AppNavigationCoordinating {
    @Published var tradeIdeaTickerToNavigate: String?

    func requestNavigation(toTicker ticker: String) {
        self.tradeIdeaTickerToNavigate = ticker
    }

    func clearTradeIdeaNavigationRequest() {
        self.tradeIdeaTickerToNavigate = nil
    }
}
