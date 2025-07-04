//
//  AppDependencies.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Combine

/// Defines the contract for the application's dependency container.
/// Any object conforming to this can be used as the central source for shared services.
protocol AppDependencies: ObservableObject {
    var persistenceHandler: PersistenceHandling { get }
    var settingsManager: SettingsManaging { get }
    var ignoreManager: IgnoreManaging { get }
    var snoozeManager: SnoozeManaging { get }
    var tickerProvider: TickerProviding { get }
    var notificationsHandler: NotificationHandling { get }
    var tickerStore: TickerStoreManaging { get }
    var chartingService: ChartingService { get }
    // MARK: - New Checklist Services
    var checklistTemplateProvider: ChecklistTemplateProviding { get }
    var checklistStateManager: ChecklistStateManaging { get }
    var imagePersister: ImagePersisting { get }
    var reportGenerator: ReportGenerating { get }
    var fileLocationProvider: FileLocationProviding { get }
}
