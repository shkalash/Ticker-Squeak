//
//  AsyncLoadedViewModel.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/6/25.
//

import Foundation
@MainActor
protocol AsyncLoadedViewModel {
    var isLoading: Bool { get }
    /// Loads the viewModel and its most recent state.
    func load() async
}
