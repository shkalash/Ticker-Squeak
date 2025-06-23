//
//  TVSettingsViewModel.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/22/25.
//

import Foundation
import AppKit
import Carbon.HIToolbox


class TVViewModel: ObservableObject {
    @Published var settings: TVSettingsData {
        didSet {
            save()
        }
    }
    
    @Published var hasAccessToAccessibilityAPI: Bool = false

    private let key = "TVSettingsData"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(TVSettingsData.self, from: data) {
            settings = decoded
        } else {
            settings = .default
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func requestAccess(){
        #if DEBUG
        if DesignMode.isRunning {
            hasAccessToAccessibilityAPI = true
            return
        }
        #endif
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        hasAccessToAccessibilityAPI = AXIsProcessTrustedWithOptions(options)
    }
        
    func showSymbolInTradingView(_ symbol:String){
        guard settings.useTradingView else {
            //print("TradingView automation disabled.")
            return
        }
        activateTradingView()
        sendSymbolToTradingView(symbol)
    }
    
    private func activateTradingView() {
        let bundleID = "com.tradingview.tradingviewapp.desktop"
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        
        if let app = apps.first {
           // print("Found TradingView. Activating...")
            
            app.activate(options: [.activateAllWindows])
            
            // Optional: explicitly bring app to front (fallback)
            NSWorkspace.shared.frontmostApplication?.unhide()
        } else {
            print("TradingView is not running.")
        }
    }
    
    private func sendSymbolToTradingView(_ symbol: String) {
        focusTradingViewAndSendTabSwitch { [self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + settings.delayBeforeTyping) { [self] in
                // Ensure no modifiers are stuck
                CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)?.post(tap: .cghidEventTap)

                for (index, char) in symbol.uppercased().enumerated() {
                    if let key = keyCodeForChar(char) {
                        let delay = settings.delayBetweenCharacters * Double(index)
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
                            //print("Typing: \(char) [keyCode \(key)]")
                            sendKeyPress(key: key)
                        }
                    }
                }

                let totalTypingDelay = settings.delayBetweenCharacters * Double(symbol.count + 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + totalTypingDelay) { [self] in
                    sendKeyPress(key: CGKeyCode(kVK_Return))
                }
            }
        }
    }

    
    func focusTradingViewAndSendTabSwitch(completion: @escaping () -> Void) {
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == "TradingView" }) {
            app.activate(options: [.activateAllWindows])

            DispatchQueue.main.asyncAfter(deadline: .now() + settings.delayBeforeTab) {
                guard self.settings.changeTab else {
                    completion()
                    return
                }

                let source = CGEventSource(stateID: .hidSystemState)
                let key = CGKeyCode(self.keyCodeForNumber(self.settings.tabNumber))

                let modifierFlags = self.modifierToCGEventFlag(self.settings.tabModifier)

                let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
                keyDown?.flags = modifierFlags

                let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
                keyUp?.flags = modifierFlags

                keyDown?.post(tap: .cghidEventTap)
                keyUp?.post(tap: .cghidEventTap)

                completion()
            }
        } else {
            print("TradingView not running.")
        }
    }

    private func sendKeyPress(key: CGKeyCode) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        keyDown?.flags = []
        keyUp?.flags = []
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    private func modifierToCGEventFlag(_ modifier: TVSettingsData.ModifierKey) -> CGEventFlags {
        switch modifier {
        case .command: return .maskCommand
        case .control: return .maskControl
        case .option: return .maskAlternate
        case .shift: return .maskShift
        case .none: return []
        }
    }
    
    private func keyCodeForChar(_ char: Character) -> CGKeyCode? {
        let upper = String(char).uppercased()
        let map: [Character: CGKeyCode] = [
            "A": 0, "B": 11, "C": 8, "D": 2, "E": 14, "F": 3, "G": 5, "H": 4, "I": 34,
            "J": 38, "K": 40, "L": 37, "M": 46, "N": 45, "O": 31, "P": 35, "Q": 12,
            "R": 15, "S": 1, "T": 17, "U": 32, "V": 9, "W": 13, "X": 7, "Y": 16,
            "Z": 6, "0": 29, "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22,
            "7": 26, "8": 28, "9": 25, " ": 49, ",": 43, ".": 47, "!": 18 // '!' uses Shift+1
        ]
        return map[upper.first!]
    }

    
    private func keyCodeForNumber(_ number: Int) -> Int {
        // ANSI 1 = 18, 2 = 19, ..., 0 = 29
        switch number {
        case 1...9: return 17 + number
        case 0: return 29
        default: return 0 // fallback, maybe Escape or A
        }
    }

}
