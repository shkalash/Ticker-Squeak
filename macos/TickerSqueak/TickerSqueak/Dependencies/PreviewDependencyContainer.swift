/// A mutable implementation of `AppDependencies` used for SwiftUI Previews and testing.
/// It is initialized with placeholder services, which can be replaced as needed for specific previews.

import Combine
import UserNotifications
import AppKit
class PreviewDependencyContainer: AppDependencies {
    var persistenceHandler: PersistenceHandling
    var settingsManager: SettingsManaging
    var ignoreManager: IgnoreManaging
    var snoozeManager: SnoozeManaging
    var tickerProvider: TickerProviding
    var notificationsHandler: NotificationHandling
    var tickerStore: TickerStoreManaging
    var chartingService: ChartingService
    var checklistTemplateProvider: ChecklistTemplateProviding
    var checklistStateManager: ChecklistStateManaging
    var imagePersister: TradeIdeaImagePersisting
    var reportGenerator: ReportGenerating
    var fileLocationProvider: FileLocationProviding
    
    init() {
        // Initialize with default placeholder implementations.
        self.persistenceHandler = PlaceholderPersistenceHandler()
        self.settingsManager = PlaceholderSettingsManager()
        self.ignoreManager = PlaceholderIgnoreManager()
        self.snoozeManager = PlaceholderSnoozeManager()
        self.tickerProvider = PlaceholderTickerProvider()
        self.notificationsHandler = PlaceholderNotificationHandler()
        self.tickerStore = PlaceholderTickerStore()
        self.chartingService = CompositeChartingService(services: [OneOptionService(settingsManager: settingsManager) , TradingViewService(settingsManager: settingsManager)])
        self.checklistTemplateProvider = PlaceholderChecklistTemplateProvider()
        self.checklistStateManager = PlaceholderChecklistStateManager()
        self.imagePersister = PlaceholderImagePersister()
        self.reportGenerator = PlaceholderReportGenerator()
        self.fileLocationProvider = PlaceholderFileLocationProvider()
    }
}


// MARK: - Stateful Placeholder Implementations for Previews

class PlaceholderPersistenceHandler: PersistenceHandling {
    func load<T>(for key: PersistenceKey<T>) -> T? {
        storage[key.name] as? T
    }
    
    func save<T>(value: T?, for key: PersistenceKey<T>) {
        storage[key.name] = value
    }
    
    private var storage: [String: Any] = [:]
    func save<T: Codable>(object: T?, for key: PersistenceKey<T>) { storage[key.name] = object }
    func load<T: Codable>(for key: PersistenceKey<T>) -> T? { storage[key.name] as? T }
}

class PlaceholderSettingsManager: SettingsManaging {
    private let subject: CurrentValueSubject<AppSettings, Never>
    var settingsPublisher: AnyPublisher<AppSettings, Never> { subject.eraseToAnyPublisher() }
    var currentSettings: AppSettings { subject.value }

    init(initialSettings: AppSettings = AppSettings()) {
        self.subject = CurrentValueSubject(initialSettings)
    }
    
    func modify(_ block: (inout AppSettings) -> Void) {
        var settings = subject.value
        block(&settings)
        subject.send(settings)
    }
}

class PlaceholderIgnoreManager: IgnoreManaging {
    func isIgnored(ticker: String) -> Bool {
        return subject.value.contains(ticker)
    }
    
    private let subject = CurrentValueSubject<[String], Never>(["MSFT", "TSLA"])
    var ignoreList: AnyPublisher<[String], Never> { subject.eraseToAnyPublisher() }
    
    func addToIgnoreList(_ ticker: String) {
        let upperTicker = ticker.uppercased()
        if !subject.value.contains(upperTicker) { subject.value.append(upperTicker) }
    }
    func removeFromIgnoreList(_ ticker: String) { subject.value.removeAll { $0 == ticker.uppercased() } }
    func clearIgnoreList() { subject.value.removeAll() }
}

class PlaceholderSnoozeManager: SnoozeManaging {
    private let subject = CurrentValueSubject<Set<String>, Never>(["GOOG"])
    var snoozedTickers: AnyPublisher<Set<String>, Never> { subject.eraseToAnyPublisher() }
    
    func setSnooze(for ticker: String , isSnoozed: Bool) { subject.value.insert(ticker.uppercased()) }
    func isSnoozed(ticker: String) -> Bool { subject.value.contains(ticker.uppercased()) }
    func remove(ticker: String) { subject.value.remove(ticker.uppercased()) }
    func clearSnoozeList() { subject.value.removeAll() }
}

class PlaceholderTickerProvider: TickerProviding {
    var payloadPublisher = PassthroughSubject<TickerPayload, Never>()
    var isRunningPublisher = CurrentValueSubject<Bool, Never>(true)
    func start() { isRunningPublisher.send(true) }
    func stop() { isRunningPublisher.send(false) }
}

class PlaceholderNotificationHandler: NotificationHandling {
    let toastPublisher = PassthroughSubject<Toast, Never>()
    var authorizationStatus: AnyPublisher<UNAuthorizationStatus, Never> = Just(.authorized).eraseToAnyPublisher()
    func requestPermission() {}
    func showNotification(for ticker: String, isHighPriority: Bool) {}
}

class PlaceholderTickerStore: TickerStoreManaging {
    private let subject: CurrentValueSubject<[TickerItem], Never>
    var allTickers: AnyPublisher<[TickerItem], Never> { subject.eraseToAnyPublisher() }

    private let hiddenSubject: CurrentValueSubject<[String], Never>
    var hiddenTickers: AnyPublisher<[String], Never> { hiddenSubject.eraseToAnyPublisher() }
    
    init() {
        let items: [TickerItem] = [
            TickerItem(ticker: "AAPL", receivedAt: Date(), isUnread: true),
            TickerItem(ticker: "NVDA", receivedAt: Date().addingTimeInterval(-60), isStarred: true),
            TickerItem(ticker: "AMD", receivedAt: Date().addingTimeInterval(-120), isUnread: false),
            TickerItem(ticker: "INTC", receivedAt: Date().addingTimeInterval(-180), direction: .bearish),
            TickerItem(ticker: "QCOM", receivedAt: Date().addingTimeInterval(-240), isUnread: true, direction: .bullish),
        ]
        let hiddens: [String] = ["SPY" , "QQQ"]
        self.subject = CurrentValueSubject(items)
        self.hiddenSubject = CurrentValueSubject(hiddens)
    }
    
    private func updateItem(id: String, _ block: (inout TickerItem) -> Void) {
        guard let index = subject.value.firstIndex(where: { $0.id == id }) else { return }
        var item = subject.value[index]
        block(&item)
        subject.value[index] = item
    }

    func handle(payload: TickerPayload) {
        let newItem = TickerItem(ticker: payload.ticker, receivedAt: Date())
        subject.value.insert(newItem, at: 0)
    }
    
    func markAsRead(id: String) { updateItem(id: id) { $0.isUnread = false } }
    func toggleUnread(id: String) { updateItem(id: id) { $0.isUnread.toggle() } }
    func toggleStarred(id: String) { updateItem(id: id) { $0.isStarred.toggle() } }
    func updateDirection(id: String, direction: TickerItem.Direction) { updateItem(id: id) { $0.direction = direction } }
    func removeItem(id: String) { subject.value.removeAll { $0.id == id } }
    func clearAll() { subject.value.removeAll() }
    func hideTicker(id: String) { hiddenSubject.value.append(id) }
    func revealTicker(_ ticker: String) {hiddenSubject.value.removeAll { $0 == ticker }}
    
}
// MARK: - New Placeholder Implementations for Checklist

class PlaceholderChecklistTemplateProvider: ChecklistTemplateProviding {
    func loadChecklistTemplate(forName name: String) async throws -> Checklist {
        // Update this to load the real file from the app's bundle for a realistic preview.
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            fatalError("Preview failed: could not find \(name).json in bundle.")
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Checklist.self, from: data)
    }
}

class PlaceholderChecklistStateManager: ChecklistStateManaging {
    private var storage: [String: ChecklistState] = [:]
    func loadState(forChecklistName checklistName: String) async ->  ChecklistState? { storage[checklistName] }
    func saveState(_ state: ChecklistState, forChecklistName checklistName: String) async { storage[checklistName] = state }
}

class PlaceholderImagePersister: TradeIdeaImagePersisting {
    
    func deleteImage(withFilename filename: String) async throws { }
    func saveImage(_ image: NSImage) async throws -> String { "preview-image.png" }
    func loadImage(withFilename filename: String) async -> NSImage? { NSImage(systemSymbolName: "photo.fill", accessibilityDescription: nil) }
}

class PlaceholderReportGenerator: ReportGenerating {
    func generateMarkdownReport(for checklist: Checklist, withState state: [String : ChecklistItemState]) -> String {
        "## This is a preview report.\n- [x] Item 1\n- [ ] Item 2"
    }
}

class PlaceholderFileLocationProvider: FileLocationProviding {

    private let fileManager: FileManager
    private let rootTempURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        // Create a unique directory for this preview session to prevent state leakage between previews.
        self.rootTempURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }
    
    // The implementation is now identical to the real one, but uses our unique temp URL as the base.
    // This makes it a true-to-life but safe "fake" implementation.
    
    func getChecklistsDirectory() throws -> URL {
        return try getOrCreateTempDirectory(appending: "Checklists")
    }

    func getMediaDirectory() throws -> URL {
        return try getOrCreateTempDirectory(appending: "Media")
    }

    func getPreMarketLogDirectory() throws -> URL {
        return try getOrCreateTempDirectory(appending: "Logs/pre-market")
    }

    func getTradesLogDirectory(for date: Date) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yy"
        let dailyFolderName = dateFormatter.string(from: date)
        let path = "Logs/trades/\(dailyFolderName)"
        return try getOrCreateTempDirectory(appending: path)
    }
    
    private func getOrCreateTempDirectory(appending pathComponent: String) throws -> URL {
        let finalDirectoryURL = self.rootTempURL.appendingPathComponent(pathComponent)
        
        // No need to report errors to the user in a preview; if this fails, we want to know immediately.
        if !fileManager.fileExists(atPath: finalDirectoryURL.path) {
            try fileManager.createDirectory(at: finalDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return finalDirectoryURL
    }
}
