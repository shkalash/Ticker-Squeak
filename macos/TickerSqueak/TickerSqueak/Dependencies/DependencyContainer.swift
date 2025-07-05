//
//  DependencyContainer.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Foundation

/// A container for all the major services and dependencies in the application.
///
/// An instance of this class is created once when the app launches and is injected
/// into the SwiftUI environment, making all services available to any view that needs them.
/// This acts as the "Composition Root" of the app.
@MainActor
class DependencyContainer: AppDependencies {
    // MARK: - Public Properties (Services)
    
    let persistenceHandler: PersistenceHandling
    let settingsManager: SettingsManaging
    let ignoreManager: IgnoreManaging
    let snoozeManager: SnoozeManaging
    let tickerProvider: TickerProviding
    let notificationsHandler: NotificationHandling
    let tickerStore: TickerStoreManaging
    let chartingService: ChartingService
    let checklistTemplateProvider: ChecklistTemplateProviding
    let checklistStateManager: ChecklistStateManaging
    let imagePersister: ImagePersisting
    let fileLocationProvider: FileLocationProviding
    let tradeIdeaManager: TradeIdeaManaging
    let preMarketReportGenerator: PreMarketReportGenerating
    let tradeIdeaReportGenerator: TradeIdeaReportGenerating
    let appCoordinator: any AppNavigationCoordinating
    let pickerOptionsProvider: PickerOptionsProviding
    // MARK: - Lifecycle
    
    init() {
        // Initialize all services in the correct order, using the specified concrete types.
        
        // 1. Persistence is the foundation.
        self.persistenceHandler = UserDefaultsPersistenceHandler()
        
        // 2. Settings depends on persistence.
        self.settingsManager = AppSettingsManager(persistence: persistenceHandler)
        
        // 3. Independent managers that depend on persistence and/or settings.
        self.ignoreManager = StandardIgnoreManager(persistence: persistenceHandler)
        self.snoozeManager = TimerBasedSnoozeManager(persistence: persistenceHandler, settingsManager: settingsManager)
        
        // 4. Network and notification services.
        self.tickerProvider = NetworkTickerProvider(settingsManager: settingsManager)
        self.notificationsHandler = AppNotificationHandler(settingsManager: settingsManager)
        
        // Create the individual charting services
        let tradingViewService = TradingViewService(settingsManager: self.settingsManager)
        let oneOptionService = OneOptionService(settingsManager: self.settingsManager)

        // Create the composite service that the app will use
        self.chartingService = CompositeChartingService(services: [tradingViewService, oneOptionService])
        
        // Foundational services that others depend on
        fileLocationProvider = LocalFileLocationProvider()
        
        self.checklistTemplateProvider = LocalChecklistTemplateProvider(fileLocationProvider: fileLocationProvider)
        self.checklistStateManager = DefaultChecklistStateManager(persistence: self.persistenceHandler)
        self.imagePersister = FileSystemImagePersister(fileLocationProvider: fileLocationProvider)
        
        self.preMarketReportGenerator = MarkdownPreMarketReportGenerator(imagePersister: imagePersister)
        
        self.tradeIdeaReportGenerator = MarkdownTradeIdeaReportGenerator(imagePersister: imagePersister)
        
        // 5. The main TickerStore, which coordinates many of the other services.
        self.tickerStore = TickerManager(
            tickerReceiver: tickerProvider,
            ignoreManager: ignoreManager,
            snoozeManager: snoozeManager,
            settingsManager: settingsManager,
            notificationHandler: notificationsHandler,
            persistence: persistenceHandler
        )
        
        self.tradeIdeaManager = FileBasedTradeIdeaManager(fileLocationProvider: fileLocationProvider, imagePersister: imagePersister)
        
        self.appCoordinator = AppCoordinator()
        
        self.pickerOptionsProvider = LocalPickerOptionsProvider(templatePrivder: checklistTemplateProvider) 
    }
}
