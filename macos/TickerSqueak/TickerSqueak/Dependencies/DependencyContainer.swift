//
//  DependencyContainer.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Foundation
import SwiftData
import CloudKit
/// A container for all the major services and dependencies in the application.
///
/// An instance of this class is created once when the app launches and is injected
/// into the SwiftUI environment, making all services available to any view that needs them.
/// This acts as the "Composition Root" of the app.
@MainActor
class DependencyContainer: AppDependencies {
    // MARK: - Public Properties (Services)
    
    let persistenceHandler: PersistenceHandling // Kept temporarily for migration
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    let settingsManager: SettingsManaging
    let ignoreManager: IgnoreManaging
    let snoozeManager: SnoozeManaging
    let tickerProvider: TickerProviding
    let notificationsHandler: NotificationHandling
    let tickerStore: TickerStoreManaging
    let chartingService: ChartingService
    let checklistTemplateProvider: ChecklistTemplateProviding
    let preMarketLogManager: any PreMarketLogManaging
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
        
        // 1. Set up SwiftData ModelContainer with CloudKit
        let schema = Schema([
            TickerItemModel.self,
            AppSettingsModel.self,
            IgnoredTickerModel.self,
            SnoozedTickerModel.self,
            SnoozeMetadataModel.self,
            ChecklistStateModel.self,
            TradeIdeaModel.self,
            PreMarketLogModel.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            self.modelContainer = try ModelContainer(for: schema,configurations: [configuration])
            self.modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // Keep UserDefaults handler temporarily for migration only
        self.persistenceHandler = UserDefaultsPersistenceHandler()
        
        // Run migration if needed
        DataMigrator.migrateToSwiftData(
            modelContext: modelContext,
            persistenceHandler: persistenceHandler,
            fileLocationProvider: LocalFileLocationProvider()
        )
        
        // 2. Settings depends on SwiftData.
        self.settingsManager = AppSettingsManager(modelContext: modelContext)
        
        // 3. Independent managers that depend on SwiftData and/or settings.
        self.ignoreManager = StandardIgnoreManager(modelContext: modelContext)
        self.snoozeManager = TimerBasedSnoozeManager(modelContext: modelContext, settingsManager: settingsManager)
        
        // 4. Network and notification services.
        self.tickerProvider = NetworkTickerProvider(settingsManager: settingsManager)
        self.notificationsHandler = AppNotificationHandler(settingsManager: settingsManager)
        
        // Create the individual charting services
        let tradingViewService = TradingViewService(settingsManager: self.settingsManager)
        let oneOptionService = OneOptionService(settingsManager: self.settingsManager)
        let tc2000Service = TC2000BridgeService(settingsManager: self.settingsManager)

        // Create the composite service that the app will use
        self.chartingService = CompositeChartingService(services: [tradingViewService, oneOptionService, tc2000Service])
        
        // Foundational services that others depend on
        fileLocationProvider = LocalFileLocationProvider()
        
        self.checklistTemplateProvider = LocalChecklistTemplateProvider(fileLocationProvider: fileLocationProvider)
        self.preMarketLogManager = SwiftDataPreMarketLogManager(modelContext: modelContext)
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
            modelContext: modelContext
        )
        
        self.tradeIdeaManager = SwiftDataTradeIdeaManager(modelContext: modelContext, imagePersister: imagePersister)
        
        self.appCoordinator = AppCoordinator()
        
        self.pickerOptionsProvider = LocalPickerOptionsProvider(templatePrivder: checklistTemplateProvider) 
    }
    
}
