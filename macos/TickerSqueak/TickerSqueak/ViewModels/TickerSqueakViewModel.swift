import Foundation
import Swifter
import UserNotifications
import AppKit

class TickerSqueakViewModel: ObservableObject {
    
    private let server = HttpServer()
    public private(set) var serverPort: Int = TickerSqueakApp.DEFAULT_SERVER_PORT
    private var receivedTickers = Set<String>()
    
    /// A dictionary to hold the scheduled tasks for removing tickers from the `receivedTickers` set.
    private var pendingRemovals: [String: DispatchWorkItem] = [:]

    @Published private(set) var isServerRunning = false
    @Published var tickerList: [TickerItem] = [] {
        didSet {
            // Recalculate unread count whenever the list changes.
            updateUnreadCount()
        }
    }
    @Published var ignoreList: [String] = []
    
    // --- Renamed and New Filter Properties ---
    @Published var showStarredOnly = false {
        didSet{
            UserDefaults.standard.set(showStarredOnly, forKey: showStarredKey)
        }
    }
    @Published var showUnreadOnly = false {
        didSet {
            UserDefaults.standard.set(showUnreadOnly, forKey: showUnreadKey)
        }
    }
    @Published private(set) var unreadCount: Int = 0
    
    @Published var showBullish = true
    @Published var showBearish = true
    @Published var toastMessage: Toast?
    @Published var alertSound: String = "" {
        didSet {
            UserDefaults.standard.set(alertSound, forKey: alertSoundFile)
        }
    }
    @Published var highPriorityAlertSound: String = ""{
        didSet {
            UserDefaults.standard.set(highPriorityAlertSound, forKey: highPriorityAlertSoundFile)
        }
    }
    @Published var muteNotifications: Bool = false {
        didSet {
            Task{
                await SoundManager.shared.setMuted(muteNotifications)
            }
        }
    }
    
    @Published var removalDelay: TimeInterval = 300 {
        didSet {
            UserDefaults.standard.set(removalDelay, forKey: removalDelayKey)
        }
    }
    
    // Persistence keys
    private let tickersKey = "SavedTickers"
    private let ignoreKey = "SavedIgnoreList"
    private let showStarredKey = "ShowStarredOnly"
    private let showUnreadKey = "ShowUnreadOnly"
    private let serverPortKey = "ServerPort"
    private let alertSoundFile = "alertSound"
    private let highPriorityAlertSoundFile = "highPriorityAlertSound"
    private let removalDelayKey = "RemovalDelay"
    
    init() {
        loadPersistence()
    }
    
    // --- Server and Notification Logic ---
    
    func setServerPort(_ port: Int) {
        saveServerPort(port)
        stopServer()
        startServer()
    }
    
    func stopServer() {
        guard isServerRunning else { return }
        #if DEBUG
        if DesignMode.isRunning {
            isServerRunning = false
            return
        }
        #endif
        server.stop()
        isServerRunning = false
    }
    
    func startServer() {
        guard !isServerRunning else { return }
        isServerRunning = true
        #if DEBUG
        if DesignMode.isRunning {
            return
        }
        #endif
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
                ErrorManager.shared.report(AppError.generalError(description: "Notifications not allowed"))
            }
        }
    }
    
    private func handleTicker(_ ticker: String , highPriority: Bool) {
        if ignoreList.contains(ticker) { return }

        if let pendingRemovalTask = pendingRemovals[ticker] {
            pendingRemovalTask.cancel()
            pendingRemovals.removeValue(forKey: ticker)
        }
        
        if receivedTickers.contains(ticker) {
            guard highPriority else {
                return
            }
            
            if let index = tickerList.firstIndex(where: { $0.ticker == ticker }) {
                 tickerList[index].isUnread = true
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
        showNotification(for: ticker , highPriority: highPriority)
    }
    
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
    
    func showNotification(for ticker: String, highPriority: Bool) {
        if isAppActive {
            showToast(for: ticker , highPriority: highPriority)
        } else {
            let content = UNMutableNotificationContent()
            content.title = highPriority ? "‼️ Ticker Alert ‼️" : "Ticker Alert"
            content.body = ticker
            content.sound = nil
            let sound = highPriority ? highPriorityAlertSound : alertSound
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
            Task{
                await SoundManager.shared.playSoundForNotification(named: sound, cooldown: 2)
            }
        }
    }
    
    private var isAppActive: Bool {
        NSApplication.shared.isActive
    }

    func showToast(for ticker: String , highPriority: Bool = false) {
        toastMessage = Toast(style: highPriority ? .warning : .info, message: "Ticker Alert \(ticker)" ,
                             duration: 2.0, width: 350.0 , sound: highPriority ? highPriorityAlertSound : alertSound)
    }

    // --- List Management ---

    func clearTickers() {
        for (_, task) in pendingRemovals {
            task.cancel()
        }
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

    // --- Ignore List Management ---
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
    
    // --- Unread Count ---
    private func updateUnreadCount() {
        unreadCount = tickerList.filter { $0.isUnread }.count
    }

    // --- Persistence ---
    private func saveTickers() {
        if let data = try? JSONEncoder().encode(tickerList) {
            UserDefaults.standard.set(data, forKey: tickersKey)
        }
    }

    private func loadPersistence() {
        if let data = UserDefaults.standard.data(forKey: tickersKey),
           let savedTickers = try? JSONDecoder().decode([TickerItem].self, from: data) {
            tickerList = savedTickers
            receivedTickers = Set(savedTickers.map { $0.ticker })
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
}

