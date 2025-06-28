//
//  ChartingSettingsViewModel.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/27/25.
//
import Combine
import SwiftUI


@MainActor
class ChartingSettingsViewModel: ObservableObject {
    @Published var chartingSettings = ChartingSettings()
    @Published var hasAccessToAccessibilityAPI: Bool = false
    
    private let settingsManager: SettingsManaging
    private var cancellables = Set<AnyCancellable>()
    
    init(dependencies: any AppDependencies) {
        self.settingsManager = dependencies.settingsManager
        
        // One subscription to get the whole charting settings object
        settingsManager.settingsPublisher
            .map(\.charting)
            .removeDuplicates()
            .assign(to: &$chartingSettings)
        
        checkAccessibilityStatus()
    }
    
    func checkAccessibilityStatus(){
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false] as CFDictionary
        hasAccessToAccessibilityAPI = AXIsProcessTrustedWithOptions(options)
    }
    
    func requestAccessibilityPermission() {
        #if DEBUG
        if DesignMode.isRunning {
            hasAccessToAccessibilityAPI = true
            return
        }
        #endif
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        hasAccessToAccessibilityAPI = AXIsProcessTrustedWithOptions(options)
    }
    
    func setChartingSettings(_ newSettings: ChartingSettings) {
        settingsManager.modify { $0.charting = newSettings }
    }
}
