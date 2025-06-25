import Foundation
import Swifter
import UserNotifications
import AppKit

class TickerSqueakViewModel: ObservableObject {
    
    // MARK: - Properties
    private let server = HttpServer()
    public private(set) var serverPort: Int = TickerSqueakApp.DEFAULT_SERVER_PORT
    private var receivedTickers = Set<String>()
    private var pendingRemovals: [String: DispatchWorkItem] = [:]
    private var snoozeClearTimer: Timer?

    // MARK: Published Properties
    @Published private(set) var isServerRunning = false
    @Published var tickerList: [TickerItem] = [] {
        didSet { updateUnreadCount() }
    }
    @Published var ignoreList: [String] = []
    @Published var snoozedTickers = Set<String>()
    
    // Filters
    @Published var showStarredOnly = false {
        didSet{ UserDefaults.standard.set(showStarredOnly, forKey: showStarredKey) }
    }
    @Published var showUnreadOnly = false {
        didSet { UserDefaults.standard.set(showUnreadOnly, forKey: showUnreadKey) }
    }
    @Published private(set) var unreadCount: Int = 0
    @Published var showBullish = true
    @Published var showBearish = true
    
    // Settings
    @Published var toastMessage: Toast?
    @Published var alertSound: String = "" {
        didSet { UserDefaults.standard.set(alertSound, forKey: alertSoundFile) }
    }
    @Published var highPriorityAlertSound: String = ""{
        didSet { UserDefaults.standard.set(highPriorityAlertSound, forKey: highPriorityAlertSoundFile) }
    }
    @Published var muteNotifications: Bool = false {
        didSet { Task { await SoundManager.shared.setMuted(muteNotifications) } }
    }
    @Published var removalDelay: TimeInterval = 300 {
        didSet { UserDefaults.standard.set(removalDelay, forKey: removalDelayKey) }
    }
    
    @Published var snoozeClearTime: Date = TickerSqueakViewModel.defaultSnoozeClearTime() {
        didSet {
            UserDefaults.standard.set(snoozeClearTime, forKey: snoozeClearTimeKey)
            scheduleNextSnoozeClear()
        }
    }
    
    // MARK: Persistence Keys
    private let tickersKey = "SavedTickers"
    private let ignoreKey = "SavedIgnoreList"
    private let showStarredKey = "ShowStarredOnly"
    private let showUnreadKey = "ShowUnreadOnly"
    private let serverPortKey = "ServerPort"
    private let alertSoundFile = "alertSound"
    private let highPriorityAlertSoundFile = "highPriorityAlertSound"
    private let removalDelayKey = "RemovalDelay"
    private let snoozedTickersKey = "SnoozedTickers"
    private let lastSnoozeClearDateKey = "LastSnoozeClearDate"
    private let snoozeClearTimeKey = "SnoozeClearTime"
    
    // MARK: - Lifecycle
    init() {
        loadPersistence()
        setupSnoozeListManagement()
    }
    
    // MARK: - Server and Notification Logic
    
    func setServerPort(_ port: Int) {
        saveServerPort(port)
        stopServer()
        startServer()
    }
    
    func stopServer() {
        guard isServerRunning else { return }
        if DesignMode.isRunning {
            isServerRunning = false
            return
        }
        server.stop()
        isServerRunning = false
    }
    
    func startServer() {
        guard !isServerRunning else { return }
        isServerRunning = true
        if DesignMode.isRunning { return }
        
        server["/notify"] = { request in
            let bodyData = Data(request.body)

            if let json = try? JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any],
               let tickerRaw = json["ticker"] as? String {
                let ticker = tickerRaw.uppercased()
                let highPriority = (json["highPriority"] as? Bool) ?? false

                DispatchQueue.main.async {
                    self.handleTicker(ticker, highPriority: highPriority)
                }
            }
            return .ok(.text("OK"))
        }

        do {
            try server.start(in_port_t(serverPort), forceIPv4: true)
            print("[TickerSqueak] Server running on port \(serverPort)")
        } catch {
            isServerRunning = false
            ErrorManager.shared.report(AppError.networkError(description: "Failed to start server: \(error.localizedDescription)"))
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if !granted {
                ErrorManager.shared.report(AppError.generalError(description: "Notifications are not allowed"))
            }
        }
    }
    
    private func handleTicker(_ ticker: String, highPriority: Bool) {
        if ignoreList.contains(ticker) { return }
        if snoozedTickers.contains(ticker) && !highPriority { return }
        if pendingRemovals[ticker] != nil { return }
        
        if receivedTickers.contains(ticker) {
            guard highPriority else { return }
            
            if let index = tickerList.firstIndex(where: { $0.ticker == ticker }) {
                tickerList[index].isUnread = true
                if snoozedTickers.contains(ticker) {
                    snoozedTickers.remove(ticker)
                    saveSnoozeList()
                }
            } else {
                let newItem = TickerItem(ticker: ticker, receivedAt: Date(), isUnread: true)
                tickerList.insert(newItem, at: 0)
            }
            saveTickers()
            showNotification(for: ticker, highPriority: true)
            return
        }
        
        receivedTickers.insert(ticker)
        let newItem = TickerItem(ticker: ticker, receivedAt: Date())
        tickerList.insert(newItem, at: 0)
        saveTickers()
        showNotification(for: ticker, highPriority: highPriority)
    }
    
    func showNotification(for ticker: String, highPriority: Bool) {
        if isAppActive {
            showToast(for: ticker, highPriority: highPriority)
        } else {
            let content = UNMutableNotificationContent()
            content.title = highPriority ? "‼️ Ticker Alert ‼️" : "Ticker Alert"
            content.body = ticker
            content.sound = nil
            let sound = highPriority ? highPriorityAlertSound : alertSound
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
            Task {
                await SoundManager.shared.playSoundForNotification(named: sound, cooldown: 2)
            }
        }
    }
    
    private var isAppActive: Bool {
        return NSApplication.shared.isActive
    }

    func showToast(for ticker: String, highPriority: Bool = false) {
        toastMessage = Toast(style: highPriority ? .warning : .info, message: "Ticker Alert \(ticker)",
                             duration: 2.0, width: 350.0, sound: highPriority ? highPriorityAlertSound : alertSound)
    }

    // MARK: - List & Item Management
    
    func hideTicker(_ item: TickerItem) {
        tickerList.removeAll { $0.id == item.id }
        saveTickers()
        let ticker = item.ticker
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.receivedTickers.remove(ticker)
            self.pendingRemovals.removeValue(forKey: ticker)
        }
        pendingRemovals[ticker] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + removalDelay, execute: workItem)
    }

    func clearTickers() {
        for (_, task) in pendingRemovals { task.cancel() }
        pendingRemovals.removeAll()
        receivedTickers.removeAll()
        tickerList.removeAll()
        saveTickers()
    }
    
    func markAsRead(_ item: TickerItem) {
        if let index = tickerList.firstIndex(of: item) {
            tickerList[index].isUnread = false
            saveTickers()
        }
    }
    
    func toggleUnread(_ item: TickerItem) {
        if let index = tickerList.firstIndex(of: item) {
            tickerList[index].isUnread.toggle()
            saveTickers()
        }
    }

    func toggleStarred(_ item: TickerItem) {
        if let idx = tickerList.firstIndex(of: item) {
            tickerList[idx].isStarred.toggle()
            saveTickers()
        }
    }
    
    func updateItem(_ updated: TickerItem) {
        if let index = tickerList.firstIndex(where: { $0.id == updated.id }) {
            tickerList[index] = updated
            saveTickers()
        }
    }

    // MARK: - Ignore List Management
    
    func addToIgnore(_ ticker: String) {
        let upperTicker = ticker.uppercased()
        if !ignoreList.contains(upperTicker) {
            ignoreList.append(upperTicker)
            saveIgnoreList()
            tickerList.removeAll(where: { $0.ticker == upperTicker })
            receivedTickers.remove(upperTicker)
            saveTickers()
        }
    }

    func removeFromIgnore(_ ticker: String) {
        ignoreList.removeAll(where: { $0 == ticker })
        saveIgnoreList()
    }
    
    func clearIgnoreList() {
        ignoreList.removeAll()
        saveIgnoreList()
    }
    
    // MARK: - Snooze List Management
    
    func snoozeTicker(_ item: TickerItem) {
        snoozedTickers.insert(item.ticker)
        saveSnoozeList()
        tickerList.removeAll { $0.id == item.id }
        saveTickers()
    }

    @objc func clearSnoozeList() {
        snoozedTickers.removeAll()
        UserDefaults.standard.set(Date(), forKey: lastSnoozeClearDateKey)
        saveSnoozeList()
        print("[Snooze] Snooze list automatically cleared.")
        scheduleNextSnoozeClear()
    }
    
    private func setupSnoozeListManagement() {
        let lastClearDate = UserDefaults.standard.object(forKey: lastSnoozeClearDateKey) as? Date
        let calendar = Calendar.current
        let clearComponents = calendar.dateComponents([.hour, .minute], from: snoozeClearTime)
        
        guard let mostRecentClearTime = calendar.nextDate(after: Date(), matching: clearComponents, matchingPolicy: .nextTime, direction: .backward) else {
            return
        }
        
        if lastClearDate == nil || lastClearDate! < mostRecentClearTime {
            clearSnoozeList()
        } else {
            scheduleNextSnoozeClear()
        }
    }
    
    private func scheduleNextSnoozeClear() {
        snoozeClearTimer?.invalidate()
        let calendar = Calendar.current
        let clearComponents = calendar.dateComponents([.hour, .minute], from: snoozeClearTime)
        
        guard let nextClearDate = calendar.nextDate(after: Date(), matching: clearComponents, matchingPolicy: .nextTime) else {
            return
        }
        
        let interval = nextClearDate.timeIntervalSinceNow
        let localDateString = nextClearDate.formatted(date: .long, time: .standard)
        print("[Snooze] Next snooze clear scheduled for \(localDateString) (in \(formattedInterval(interval)))")
        
        snoozeClearTimer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(clearSnoozeList),
            userInfo: nil,
            repeats: false
        )
    }

    // MARK: - Unread Count
    
    private func updateUnreadCount() {
        unreadCount = tickerList.filter { $0.isUnread }.count
    }

    // MARK: - Persistence
    
    private func saveTickers() {
        if let data = try? JSONEncoder().encode(tickerList) {
            UserDefaults.standard.set(data, forKey: tickersKey)
        }
    }
    
    private func saveSnoozeList() {
        UserDefaults.standard.set(Array(snoozedTickers), forKey: snoozedTickersKey)
    }

    private func loadPersistence() {
        if let data = UserDefaults.standard.data(forKey: tickersKey),
           let savedTickers = try? JSONDecoder().decode([TickerItem].self, from: data) {
            tickerList = savedTickers
            receivedTickers = Set(savedTickers.map { $0.ticker })
        }
        if let snoozedArray = UserDefaults.standard.array(forKey: snoozedTickersKey) as? [String] {
            snoozedTickers = Set(snoozedArray)
        }
        if let ignoreData = UserDefaults.standard.array(forKey: ignoreKey) as? [String] {
            ignoreList = ignoreData
        }
        
        showStarredOnly = UserDefaults.standard.bool(forKey: showStarredKey)
        showUnreadOnly = UserDefaults.standard.bool(forKey: showUnreadKey)
        
        let userPort = UserDefaults.standard.integer(forKey: serverPortKey)
        if userPort > 0 { serverPort = userPort }
        
        if UserDefaults.standard.object(forKey: removalDelayKey) != nil {
             removalDelay = UserDefaults.standard.double(forKey: removalDelayKey)
        }
        
        if let savedTime = UserDefaults.standard.object(forKey: snoozeClearTimeKey) as? Date {
            snoozeClearTime = savedTime
        }
        
        let audioFiles = NSSound.bundledSoundNames
        alertSound = UserDefaults.standard.string(forKey: alertSoundFile) ?? (audioFiles.count > 0 ? audioFiles[0] : "")
        highPriorityAlertSound = UserDefaults.standard.string(forKey: highPriorityAlertSoundFile) ?? (audioFiles.count > 1 ? audioFiles[1] : "")
        
        updateUnreadCount()
    }
    
    private func saveServerPort(_ port: Int) {
        serverPort = port
        UserDefaults.standard.set(port, forKey: serverPortKey)
    }

    private func saveIgnoreList() {
        UserDefaults.standard.set(ignoreList, forKey: ignoreKey)
    }
    
    // MARK: - Helpers
    
    /// Provides a default Date object representing 6 PM in the New York time zone.
    private static func defaultSnoozeClearTime() -> Date {
        guard let nyTimeZone = TimeZone(identifier: "America/New_York") else {
            // Fallback to local 6 PM if timezone is not found
            return Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        }

        var calendar = Calendar.current
        calendar.timeZone = nyTimeZone
        
        // Build components for 6 PM in the New York timezone for the current date
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 18 // 6 PM
        components.minute = 0
        components.second = 0

        // Create the date from these components.
        return calendar.date(from: components) ?? Date()
    }
    
    private func formattedInterval(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
