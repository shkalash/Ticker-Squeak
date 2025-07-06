//
//  AppDependencies.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Combine

/// Defines the contract for the application's dependency container.
/// Any object conforming to this can be used as the central source for shared services.
@MainActor
protocol AppDependencies: ObservableObject {
    var persistenceHandler: PersistenceHandling { get }
    var settingsManager: SettingsManaging { get }
    var ignoreManager: IgnoreManaging { get }
    var snoozeManager: SnoozeManaging { get }
    var tickerProvider: TickerProviding { get }
    var notificationsHandler: NotificationHandling { get }
    var tickerStore: TickerStoreManaging { get }
    var chartingService: ChartingService { get }
    var checklistTemplateProvider: ChecklistTemplateProviding { get }
    var preMarketLogManager: any PreMarketLogManaging { get }
    var imagePersister: ImagePersisting { get }
    var preMarketReportGenerator: PreMarketReportGenerating { get }
    var tradeIdeaReportGenerator: TradeIdeaReportGenerating { get }
    var fileLocationProvider: FileLocationProviding { get }
    var tradeIdeaManager: TradeIdeaManaging { get }
    var appCoordinator: any AppNavigationCoordinating { get }
    var pickerOptionsProvider: PickerOptionsProviding { get }
}
