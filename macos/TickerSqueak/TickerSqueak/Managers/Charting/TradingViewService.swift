//
//  TradingViewService.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/27/25.
//

import Foundation
import AppKit
import Carbon.HIToolbox

/// Handles the logic for opening a ticker in TradingView.
class TradingViewService: ChartingService {
    let provider: ChartingProvider = .tradingView
    private let settingsManager: SettingsManaging

    init(settingsManager: SettingsManaging) {
        self.settingsManager = settingsManager
    }
    
    func open(ticker: String) {
        // Only proceed if this service is enabled in the user's settings.
        guard settingsManager.currentSettings.charting.tradingView.isEnabled else { return }
        
        let bundleID = "com.tradingview.tradingviewapp.desktop"
        
        // 1. Find the running TradingView application
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
            ErrorManager.shared.report(AppError.generalError(description: "TradingView is not running."))
            return
        }
        
        // 2. Activate the app and wait for it to be focused
        app.activate(options: [.activateAllWindows])
        
        waitForAppToFocus(app) { [self] in
            // 3. Once focused, optionally send the tab switch command
            sendTabSwitchIfNeeded { [self] in
                // 4. After the tab switch, begin typing the ticker sequentially
                typeSequentially(ticker: ticker.uppercased(), index: 0)
            }
        }
    }

    /// Polls every 0.1s to check if the target app is frontmost.
    private func waitForAppToFocus(_ app: NSRunningApplication, completion: @escaping () -> Void) {
        var retries = 0
        let maxRetries = 50 // Wait up to 5 seconds
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if app.isActive {
                timer.invalidate()
                completion()
            } else {
                retries += 1
                if retries >= maxRetries {
                    timer.invalidate()
                    ErrorManager.shared.report(AppError.generalError(description: "Failed to focus TradingView."))
                }
            }
        }
    }

    /// Sends the configured tab-switching shortcut after a delay.
    private func sendTabSwitchIfNeeded(completion: @escaping () -> Void) {
        guard settingsManager.currentSettings.charting.tradingView.changeTab else {
            completion()
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + settingsManager.currentSettings.charting.tradingView.delayBeforeTab) { [self] in
            let key = CGKeyCode(keyCodeForNumber(settingsManager.currentSettings.charting.tradingView.tabNumber))
            let modifierFlags = modifierToCGEventFlag(settingsManager.currentSettings.charting.tradingView.tabModifier)
            
            let source = CGEventSource(stateID: .hidSystemState)
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
            keyDown?.flags = modifierFlags
            keyDown?.post(tap: .cghidEventTap)
            
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
            keyUp?.flags = modifierFlags
            keyUp?.post(tap: .cghidEventTap)
            
            completion()
        }
    }

    ///  Types the ticker one character at a time.
    private func typeSequentially(ticker: String, index: Int) {
        // Base case: If we've typed all characters, press Return and finish.
        guard index < ticker.count else {
            DispatchQueue.main.asyncAfter(deadline: .now() + settingsManager.currentSettings.charting.tradingView.delayBetweenCharacters) { [self] in
                sendKeyPress(key: CGKeyCode(kVK_Return))
            }
            return
        }
        
        // The first character should wait for `delayBeforeTyping`
        let initialDelay = (index == 0) ? settingsManager.currentSettings.charting.tradingView.delayBeforeTyping : 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) { [self] in
            let charIndex = ticker.index(ticker.startIndex, offsetBy: index)
            let char = ticker[charIndex]
            
            if let key = keyCodeForChar(char) {
                sendKeyPress(key: key)
                
                // Recursive step: Schedule the next character to be typed.
                DispatchQueue.main.asyncAfter(deadline: .now() + settingsManager.currentSettings.charting.tradingView.delayBetweenCharacters) { [self] in
                    typeSequentially(ticker: ticker, index: index + 1)
                }
            } else {
                // If a character isn't supported, skip it and continue.
                typeSequentially(ticker: ticker, index: index + 1)
                ErrorManager.shared.report(AppError.developementError(description: "Couldn't find key code for \(char)"))
            }
        }
    }
    
    // --- HELPER FUNCTIONS ---
    
    private func sendKeyPress(key: CGKeyCode) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        // Clearing flags is important to prevent "sticky" modifiers.
        keyDown?.flags = []
        keyUp?.flags = []
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    private func modifierToCGEventFlag(_ modifier: ModifierKey) -> CGEventFlags {
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
            "7": 26, "8": 28, "9": 25, " ": 49, ",": 43, ".": 47, "!": 18
        ]
        return map[upper.first!]
    }
    
    private func keyCodeForNumber(_ number: Int) -> Int {
        switch number {
        case 1...9: return 17 + number
        case 0: return 29
        default: return 0
        }
    }
}
