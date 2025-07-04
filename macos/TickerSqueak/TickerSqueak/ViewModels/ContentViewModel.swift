//
//  ContentViewModel.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import SwiftUI
import Combine

/// The ViewModel for the main ContentView. Its only job is to manage the currently selected tab.
@MainActor
class ContentViewModel: ObservableObject {
    @AppStorage("mainViewTabIndex") var selectedTab: Int = 0
    static let tradeIdeaNavigationPublisher = PassthroughSubject<String, Never>()
}
