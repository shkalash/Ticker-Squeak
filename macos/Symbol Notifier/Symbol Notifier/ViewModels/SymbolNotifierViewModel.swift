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
    private var receivedSymbols = Set<String>()
    private var serverStarted = false
    public private(set) var serverPort: Int = Symbol_NotifierApp.DEFAULT_SERVER_PORT
    
    @Published var toastSound: String = NSSound.systemSoundNames.first ?? ""{
        didSet {
            UserDefaults.standard.set(toastSound, forKey: toastSoundKey)
        }
    }
    @Published var symbolList: [SymbolItem] = []
    @Published var ignoreList: [String] = []
    @Published var showHighlightedOnly = false
    @Published var toastMessage: Toast?
    // Persistence keys
    private let symbolsKey = "SavedSymbols"
    private let ignoreKey = "SavedIgnoreList"
    private let showHighlightedKey = "ShowHighlightedOnly"
    private let serverPortKey = "ServerPort"
    private let toastSoundKey = "ToastSound"
    
    init() {
        loadPersistence()
    }
    
    func setServerPort(_ port: Int) {
        saveServerPort(port)
        server.stop()
        serverStarted = false
        startServer()
    }
    
    func startServer() {
        guard !serverStarted else { return }
        serverStarted = true
        server["/notify"] = { request in
            let bodyData = Data(request.body)

            if let json = try? JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: String],
               let symbolRaw = json["symbol"] {
                let symbol = symbolRaw.uppercased()

                DispatchQueue.main.async {
                    self.handleSymbol(symbol)
                }
            }

            return .ok(.text("OK"))
        }

        do {
            try server.start(in_port_t(serverPort), forceIPv4: true)
            print("[Symbol Notifier] Server running on port \(serverPort)")
        } catch {
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

    private func handleSymbol(_ symbol: String) {
        // Ignore symbols in ignore list
        if ignoreList.contains(symbol) {
            return
        }
        if receivedSymbols.contains(symbol) {
            return
        }
        receivedSymbols.insert(symbol)
        let newItem = SymbolItem(symbol: symbol, receivedAt: Date())
        symbolList.insert(newItem, at: 0)
        saveSymbols()
        showNotification(for: symbol)
    }

    func showNotification(for symbol: String) {
        if isAppActive {
            // Foreground: play sound and show toast
            showToast(for: symbol)
        } else {
            // Background: show system notification with custom sound
            let content = UNMutableNotificationContent()
            content.title = "Ticker Alert"
            content.body = symbol
            content.sound = .default

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
    }

    private var isAppActive: Bool {
        NSApplication.shared.isActive
    }

    func showToast(for symbol: String) {
        toastMessage = Toast(style: .info, message: "Ticker Alert \(symbol)" , duration: 2.0, width: 350.0 , sound: toastSound)
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
        if let sound = UserDefaults.standard.string(forKey: toastSoundKey){
            toastSound = sound
        }
       
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
