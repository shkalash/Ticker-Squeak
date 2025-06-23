import Foundation
import Swifter
import UserNotifications
import AppKit

class SymbolNotifierViewModel: ObservableObject {
    
    private let server = HttpServer()
    public private(set) var serverPort: Int = Symbol_NotifierApp.DEFAULT_SERVER_PORT
    private var receivedSymbols = Set<String>()
    
    /// A dictionary to hold the scheduled tasks for removing symbols from the `receivedSymbols` set.
    private var pendingRemovals: [String: DispatchWorkItem] = [:]

    @Published private(set) var isServerRunning = false
    @Published var symbolList: [SymbolItem] = [] {
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
    private let symbolsKey = "SavedSymbols"
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
               let symbolRaw = json["symbol"] as? String {
                let symbol = symbolRaw.uppercased()
                let highPriority = (json["highPriority"] as? Bool) ?? false

                DispatchQueue.main.async {
                    self.handleSymbol(symbol, highPriority: highPriority)
                }
            }


            return .ok(.text("OK"))
        }

        do {
            try server.start(in_port_t(serverPort), forceIPv4: true)
            print("[Symbol Notifier] Server running on port \(serverPort)")
        } catch {
            isServerRunning = false
            print("[Symbol Notifier] Failed to start server:", error)
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if !granted {
                print("[Symbol Notifier] Notifications not allowed")
            }
        }
    }
    
    private func handleSymbol(_ symbol: String , highPriority: Bool) {
        if ignoreList.contains(symbol) { return }

        if let pendingRemovalTask = pendingRemovals[symbol] {
            pendingRemovalTask.cancel()
            pendingRemovals.removeValue(forKey: symbol)
            print("Cancelled pending removal for \(symbol).")
        }
        
        if receivedSymbols.contains(symbol) {
            guard highPriority else {
                print("Ignoring non-high-priority alert for recent symbol: \(symbol)")
                return
            }
            
            print("Received high-priority alert for recent symbol: \(symbol)")
            
            if let index = symbolList.firstIndex(where: { $0.symbol == symbol }) {
                 symbolList[index].isUnread = true
            } else {
                let newItem = SymbolItem(symbol: symbol, receivedAt: Date(), isUnread: true)
                symbolList.insert(newItem, at: 0)
            }
            
            saveSymbols()
            showNotification(for: symbol, highPriority: true)
            return
        }
        
        print("Received new symbol: \(symbol)")
        receivedSymbols.insert(symbol)
        let newItem = SymbolItem(symbol: symbol, receivedAt: Date())
        symbolList.insert(newItem, at: 0)
        saveSymbols()
        showNotification(for: symbol , highPriority: highPriority)
    }
    
    func hideSymbol(_ item: SymbolItem) {
        symbolList.removeAll { $0.id == item.id }
        saveSymbols()

        let symbol = item.symbol
        print("Hiding \(symbol). It will be fully removed in \(removalDelay) seconds.")

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            print("Permanently removing \(symbol) from receivedSymbols set after delay.")
            self.receivedSymbols.remove(symbol)
            self.pendingRemovals.removeValue(forKey: symbol)
        }

        pendingRemovals[symbol] = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + removalDelay, execute: workItem)
    }
    
    func showNotification(for symbol: String, highPriority: Bool) {
        if isAppActive {
            showToast(for: symbol , highPriority: highPriority)
        } else {
            let content = UNMutableNotificationContent()
            content.title = highPriority ? "‼️ Ticker Alert ‼️" : "Ticker Alert"
            content.body = symbol
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

    func showToast(for symbol: String , highPriority: Bool = false) {
        toastMessage = Toast(style: highPriority ? .warning : .info, message: "Ticker Alert \(symbol)" ,
                             duration: 2.0, width: 350.0 , sound: highPriority ? highPriorityAlertSound : alertSound)
    }

    // --- List Management ---

    func clearSymbols() {
        for (_, task) in pendingRemovals {
            task.cancel()
        }
        pendingRemovals.removeAll()
        print("Cancelled all pending symbol removals.")
        
        receivedSymbols.removeAll()
        symbolList.removeAll()
        saveSymbols()
    }
    
    func markAsRead(_ item: SymbolItem) {
        if let index = symbolList.firstIndex(of: item) {
            symbolList[index].isUnread = false
            saveSymbols()
        }
    }

    func toggleStarred(_ item: SymbolItem) {
        if let idx = symbolList.firstIndex(of: item) {
            symbolList[idx].isStarred.toggle()
            saveSymbols()
        }
    }
    
    func updateItem(_ updated: SymbolItem) {
        if let index = symbolList.firstIndex(where: { $0.id == updated.id }) {
            symbolList[index] = updated
            saveSymbols()
        }
    }

    // --- Ignore List Management ---
    func addToIgnore(_ symbol: String) {
        let upperSymbol = symbol.uppercased()
        if !ignoreList.contains(upperSymbol) {
            ignoreList.append(upperSymbol)
            saveIgnoreList()
            symbolList.removeAll(where: { $0.symbol == upperSymbol })
            receivedSymbols.remove(upperSymbol)
            saveSymbols()
        }
    }

    func removeFromIgnore(_ symbol: String) {
        ignoreList.removeAll(where: { $0 == symbol })
        saveIgnoreList()
    }
    
    func clearIgnoreList() {
        ignoreList.removeAll()
        saveIgnoreList()
    }
    
    // --- Unread Count ---
    private func updateUnreadCount() {
        unreadCount = symbolList.filter { $0.isUnread }.count
    }

    // --- Persistence ---
    private func saveSymbols() {
        if let data = try? JSONEncoder().encode(symbolList) {
            UserDefaults.standard.set(data, forKey: symbolsKey)
        }
    }

    private func loadPersistence() {
        if let data = UserDefaults.standard.data(forKey: symbolsKey),
           let savedSymbols = try? JSONDecoder().decode([SymbolItem].self, from: data) {
            symbolList = savedSymbols
            receivedSymbols = Set(savedSymbols.map { $0.symbol })
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

