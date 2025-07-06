/// A mutable implementation of `AppDependencies` used for SwiftUI Previews and testing.
/// It is initialized with placeholder services, which can be replaced as needed for specific previews.

import Combine
import UserNotifications
import AppKit
@MainActor
class PreviewDependencyContainer: AppDependencies {
    
    
    let persistenceHandler: PersistenceHandling
    let settingsManager: SettingsManaging
    let ignoreManager: IgnoreManaging
    let snoozeManager: SnoozeManaging
    let tickerProvider: TickerProviding
    let notificationsHandler: NotificationHandling
    let tickerStore: TickerStoreManaging
    let chartingService: ChartingService
    let checklistTemplateProvider: ChecklistTemplateProviding
    var preMarketLogManager: any PreMarketLogManaging
    let imagePersister: ImagePersisting
    let preMarketReportGenerator: PreMarketReportGenerating
    let tradeIdeaReportGenerator: TradeIdeaReportGenerating
    let fileLocationProvider: FileLocationProviding
    let tradeIdeaManager: any TradeIdeaManaging
    let appCoordinator: any AppNavigationCoordinating
    let pickerOptionsProvider: PickerOptionsProviding
    
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
        self.preMarketLogManager = PlaceholderPreMarketLogManager()
        self.imagePersister = PlaceholderImagePersister()
        self.preMarketReportGenerator = PlaceholderPreMarketReportGenerator()
        self.tradeIdeaReportGenerator = PlaceholderTradeIdeaReportGenerator()
        self.fileLocationProvider = PlaceholderFileLocationProvider()
        self.tradeIdeaManager = PlaceholderTradeIdeaManager()
        self.appCoordinator = PlaceholderAppCoordinator()
        self.pickerOptionsProvider = PlaceholderPickerOptionsProvider()
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
    func saveCodable<T: Codable>(object: T?, for key: PersistenceKey<T>) { storage[key.name] = object }
    func loadCodable<T: Codable>(for key: PersistenceKey<T>) -> T? { storage[key.name] as? T }
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
    func markAsStarred(id: String) { updateItem(id: id) { $0.isStarred = true} }
    
}
// MARK: - New Placeholder Implementations for Checklist

class PlaceholderChecklistTemplateProvider: ChecklistTemplateProviding {
    func loadJSONTemplate<T>(forName name: String) async throws -> T where T : Decodable {
        // Update this to load the real file from the app's bundle for a realistic preview.
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            fatalError("Preview failed: could not find \(name).json in bundle.")
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

class PlaceholderChecklistStateManager: ChecklistStateManaging {
    private var storage: [String: ChecklistState] = [:]
    func loadState(forChecklistName checklistName: String) async ->  ChecklistState? { storage[checklistName] }
    func saveState(_ state: ChecklistState, forChecklistName checklistName: String) async { storage[checklistName] = state }
}

import AppKit
import Foundation

/// An in-memory placeholder implementation of `ImagePersisting` for SwiftUI Previews.
/// It simulates file storage using a dictionary and does not interact with the file system.
class PlaceholderImagePersister: ImagePersisting {

    /// Simulates a file system where the key is the full "path" (e.g., "ideaID/filename.png").
    private var storage: [String: Data] = [:]
    
    /// Helper to create a unique storage key from the context and filename.
    private func storageKey(for context: ChecklistContext, filename: String) -> String {
        switch context {
        case .tradeIdea(let id):
            return "\(id.uuidString)/\(filename)"
        case .preMarket(let date):
            return "pre-market/\(date.description)/\(filename)"
        }
    }
    
    func saveImage(_ image: NSImage, for context: ChecklistContext) async throws -> String {
        let filename = UUID().uuidString + ".png"
        let key = storageKey(for: context, filename: filename)
        
        // We just store placeholder data, not the real image bytes.
        storage[key] = Data()
        print("Placeholder: Saved image to fake path: \(key)")
        return filename
    }

    func loadImage(withFilename filename: String, for context: ChecklistContext) async -> NSImage? {
        let key = storageKey(for: context, filename: filename)
        
        // If the key exists in our fake storage, return a system image as a placeholder.
        if storage[key] != nil {
            print("Placeholder: Loaded image from fake path: \(key)")
            return NSImage(systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: "Placeholder Image")
        } else {
            return nil
        }
    }

    func deleteImage(withFilename filename: String, for context: ChecklistContext) async throws {
        let key = storageKey(for: context, filename: filename)
        storage.removeValue(forKey: key)
        print("Placeholder: Deleted image at fake path: \(key)")
    }

    func deleteAllImages(for context: ChecklistContext) async throws {
        let prefix: String
        switch context {
        case .tradeIdea(let id):
            prefix = "\(id.uuidString)/"
        case .preMarket(let date):
            prefix = "pre-market/\(date.description)/"
        }
        
        // Remove all keys that start with the context's path prefix.
        for key in storage.keys where key.hasPrefix(prefix) {
            storage.removeValue(forKey: key)
        }
        print("Placeholder: Deleted all images for context: \(prefix)")
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

    func getPreMarketLogDirectory(forMonth date: Date) throws -> URL {
        let yearFormatter = DateFormatter()
        let yearString = yearFormatter.string(from: date)
        // A new formatter for the month number (e.g., "07")
        let monthFormatter = DateFormatter(); monthFormatter.dateFormat = "MM"
        let monthString = monthFormatter.string(from: date)
        
        let path = "pre-market-logs/\(yearString)/\(monthString)"
        return try getOrCreateTempDirectory(appending: path)
    }
    
    func getTradesLogDirectory(forYear year:Date) throws -> URL{
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        let yearString = yearFormatter.string(from: year)
        // 2. Construct the full nested path.
        let path = "Logs/trades/\(yearString)"
        return try getOrCreateTempDirectory(appending: path)
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

/// A placeholder that returns a static, sample report for the Pre-Market Checklist.
class PlaceholderPreMarketReportGenerator: PreMarketReportGenerating {
    func generateReport(for state: ChecklistState, withTemplate checklist: Checklist) -> String {
        return """
        # \(checklist.title) (Preview)
        **Date:** \(state.lastModified.formatted(date: .long, time: .omitted))

        ### Sample Section
        - [x] This is a sample completed item.
        - [ ] This is a sample pending item.
        - > This is a sample note in a text field.

        *Report generated by placeholder.*
        """
    }
}

/// A placeholder that returns a static, sample report for a Trade Idea.
class PlaceholderTradeIdeaReportGenerator: TradeIdeaReportGenerating {
    func generateReport(for idea: TradeIdea, withTemplate checklist: Checklist) async -> String {
        return """
        # \(checklist.title) for \(idea.ticker) (Preview)
        **Status:** \(idea.status.rawValue.capitalized)
        **Direction:** \(idea.direction.rawValue.capitalized)
        **Created:** \(idea.createdAt.formatted(date: .abbreviated, time: .shortened))

        ### Analysis
        - ![Placeholder Image](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=)
        - > These are sample notes from the placeholder.

        *Report generated by placeholder.*
        """
    }
}

class PlaceholderTradeIdeaManager: TradeIdeaManaging {
    /// An in-memory dictionary to act as a fake database for previews.
    private var storage: [UUID: TradeIdea] = [:]

    init() {
        // Pre-populate the storage with some interesting sample data for the preview.
        let sampleChecklistState = ChecklistState(lastModified: Date(), itemStates: [:])
        
        let idea1 = TradeIdea(id: UUID(), ticker: "AAPL", createdAt: Date(), direction: .bullish, status: .idea, decisionAt: nil, checklistState: sampleChecklistState)
        let idea2 = TradeIdea(id: UUID(), ticker: "NVDA", createdAt: Date(), direction: .bearish, status: .taken, decisionAt: Date().addingTimeInterval(-3600), checklistState: sampleChecklistState)
        let idea3 = TradeIdea(id: UUID(), ticker: "TSLA", createdAt: Date().addingTimeInterval(-7200), direction: .none, status: .rejected, decisionAt: Date().addingTimeInterval(-3000), checklistState: sampleChecklistState)
        
        // A trade idea from yesterday to test the date picker
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let idea4 = TradeIdea(id: UUID(), ticker: "GOOG", createdAt: yesterday, direction: .bullish, status: .idea, decisionAt: nil, checklistState: sampleChecklistState)


        self.storage = [
            idea1.id: idea1,
            idea2.id: idea2,
            idea3.id: idea3,
            idea4.id: idea4
        ]
    }

    func fetchIdeas(for date: Date) async -> [TradeIdea] {
        // Simulate fetching by filtering the in-memory storage.
        let ideas = storage.values.filter {
            Calendar.current.isDate($0.createdAt, inSameDayAs: date)
        }
        return ideas.sorted { $0.createdAt < $1.createdAt }
    }
    
    func fetchDatesWithEntries(forMonth month: Date) async -> Set<Date> {
        let calendar = Calendar.current
        
        // 1. Filter the in-memory ideas to find those within the same month and year.
        let ideasInMonth = storage.values.filter { idea in
            return calendar.isDate(idea.createdAt, equalTo: month, toGranularity: .month)
        }
        
        // 2. Map the results to just their dates.
        let dates = ideasInMonth.map { $0.createdAt }
        
        // 3. Normalize each date to the start of its day to ensure uniqueness.
        //    For example, two trades on July 6th at 10 AM and 2 PM become one entry for July 6th.
        let uniqueDays = dates.map { calendar.startOfDay(for: $0) }
        
        // 4. Return a Set of the unique days.
        return Set(uniqueDays)
    }
    
    func saveIdea(_ idea: TradeIdea) async {
        // Simulate saving by updating the dictionary.
        storage[idea.id] = idea
    }

    func deleteIdea(_ ideaToDelete: TradeIdea) async {
        // Simulate deleting by removing from the dictionary.
        storage.removeValue(forKey: ideaToDelete.id)
    }
    func findOrCreateIdea(forTicker ticker: String, on date: Date) async -> (idea: TradeIdea, wasCreated: Bool) {
        // Simulate the find-or-create logic against the in-memory storage.
        let ideasForDay = await fetchIdeas(for: date)
        if let existingIdea = ideasForDay.first(where: { $0.ticker.uppercased() == ticker.uppercased() }) {
            return (idea : existingIdea , wasCreated: false)
        } else {
            let newIdea = TradeIdea(
                id: UUID(),
                ticker: ticker.uppercased(),
                createdAt: Date(),
                direction: .none,
                status: .idea,
                decisionAt: nil,
                checklistState: ChecklistState(lastModified: Date(), itemStates: [:])
            )
            await saveIdea(newIdea)
            return (idea: newIdea , wasCreated: true)
        }
    }
}

class PlaceholderAppCoordinator: AppNavigationCoordinating {
    @Published var tradeIdeaTickerToNavigate: String?
    func requestNavigation(toTicker ticker: String) { self.tradeIdeaTickerToNavigate = ticker }
    func clearTradeIdeaNavigationRequest() { self.tradeIdeaTickerToNavigate = nil }
}

class PlaceholderPickerOptionsProvider: PickerOptionsProviding {
    func options(for key: String) -> [String] { ["Preview Option 1", "Preview Option 2"] }
}

class PlaceholderPreMarketLogManager: PreMarketLogManaging {
    // Implement simple in-memory versions of the methods for previews
    func saveLog(_ state: ChecklistState) async {}
    func loadLog(for date: Date) async -> ChecklistState? { return nil }
    func fetchDatesWithEntries(forMonth month: Date) async -> Set<Date> { return Set() }
}
