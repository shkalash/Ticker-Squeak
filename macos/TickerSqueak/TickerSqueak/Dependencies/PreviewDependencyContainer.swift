/// A mutable implementation of `AppDependencies` used for SwiftUI Previews and testing.
/// It is initialized with placeholder services, which can be replaced as needed for specific previews.

import Combine
import UserNotifications
class PreviewDependencyContainer: AppDependencies {
    
    var persistenceHandler: PersistenceHandling
    var settingsManager: SettingsManaging
    var ignoreManager: IgnoreManaging
    var snoozeManager: SnoozeManaging
    var tickerProvider: TickerProviding
    var notificationsHandler: NotificationHandling
    var tickerStore: TickerStoreManaging
    var chartingService: ChartingService
    
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
