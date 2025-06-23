//
//  SymbolNotifierViewModel.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/21/25.
//

import Foundation
import Swifter
import UserNotifications
import AppKit

class SymbolNotifierViewModel: ObservableObject {
    
    
    private let server = HttpServer()
    public private(set) var serverPort: Int = Symbol_NotifierApp.DEFAULT_SERVER_PORT
    private var receivedSymbols = Set<String>()

    @Published private(set) var isServerRunning = false
    @Published var symbolList: [SymbolItem] = []
    @Published var ignoreList: [String] = []
    @Published var showHighlightedOnly = false
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
    
    
    // Persistence keys
    private let symbolsKey = "SavedSymbols"
    private let ignoreKey = "SavedIgnoreList"
    private let showHighlightedKey = "ShowHighlightedOnly"
    private let serverPortKey = "ServerPort"
    private let alertSoundFile = "alertSound"
    private let highPriorityAlertSoundFile = "highPriorityAlertSound"
    
    init() {
        loadPersistence()
    }
    
    func setServerPort(_ port: Int) {
        saveServerPort(port)
        stopServer()
        startServer()
    }
    
    func stopServer() {
        guard isServerRunning else { return }
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
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
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
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
        // Ignore symbols in ignore list
        if ignoreList.contains(symbol) {
            return
        }
        if receivedSymbols.contains(symbol) {
            // Still notify for high priority
            if (highPriority){
                showNotification(for: symbol, highPriority: true)
            }
            return
        }
        receivedSymbols.insert(symbol)
        let newItem = SymbolItem(symbol: symbol, receivedAt: Date())
        symbolList.insert(newItem, at: 0)
        saveSymbols()
        showNotification(for: symbol , highPriority: highPriority)
    }
    func showNotification(for symbol: String, highPriority: Bool) {
        if isAppActive {
            showToast(for: symbol , highPriority: highPriority)
        } else {
            // Background: show system notification with custom sound
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

    func clearSymbols() {
        receivedSymbols.removeAll()
        symbolList.removeAll()
        saveSymbols()
    }

    func toggleHighlight(_ item: SymbolItem) {
        if let idx = symbolList.firstIndex(of: item) {
            symbolList[idx].isHighlighted.toggle()
            saveSymbols()
        }
    }
    
    func updateItem(_ updated: SymbolItem) {
        if let index = symbolList.firstIndex(where: { $0.id == updated.id }) {
            symbolList[index] = updated
            saveSymbols()
        }
    }

    // Ignore List Management
    func addToIgnore(_ symbol: String) {
        let upperSymbol = symbol.uppercased()
        if !ignoreList.contains(upperSymbol) {
            ignoreList.append(upperSymbol)
            saveIgnoreList()
            // Also remove from symbolList if present
            symbolList.removeAll(where: { $0.symbol == upperSymbol })
            receivedSymbols.remove(upperSymbol)
            saveSymbols()
        }
    }

    func removeFromIgnore(_ symbol: String) {
        ignoreList.removeAll(where: { $0 == symbol })
        saveIgnoreList()
    }

    // Persistence
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

        showHighlightedOnly = UserDefaults.standard.bool(forKey: showHighlightedKey)
        
        let userPort = UserDefaults.standard.integer(forKey: serverPortKey)
        if userPort > 0 {
            serverPort = userPort
        }
        
        let audioFiles = NSSound.bundledSoundNames
        alertSound = UserDefaults.standard.string(forKey: alertSoundFile) ?? audioFiles[0]
        highPriorityAlertSound = UserDefaults.standard.string(forKey: highPriorityAlertSoundFile) ?? audioFiles[1]
    }
    
    
    private func saveServerPort(_ port: Int) {
        serverPort = port
        UserDefaults.standard.set(port, forKey: serverPortKey)
    }

    private func saveIgnoreList() {
        UserDefaults.standard.set(ignoreList, forKey: ignoreKey)
    }

    func setShowHighlightedOnly(_ value: Bool) {
        showHighlightedOnly = value
        UserDefaults.standard.set(value, forKey: showHighlightedKey)
    }

    func clearIgnoreList() {
        ignoreList.removeAll()
        saveIgnoreList()
    }
}
