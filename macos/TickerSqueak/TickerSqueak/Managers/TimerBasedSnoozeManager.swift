//
//  TimerBasedSnoozeManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Combine
import Foundation


// MARK: - Snooze Manager

class TimerBasedSnoozeManager: SnoozeManaging {
    
    var snoozedTickers: AnyPublisher<Set<String>, Never> {
        $internalSnoozedTickers.eraseToAnyPublisher()
    }
    
    @Published private var internalSnoozedTickers: Set<String>
    
    private var snoozeClearTimer: Timer?
    private let persistence: PersistenceHandling
    private let settingsManager: SettingsManaging
    private var cancellables = Set<AnyCancellable>()

    init(persistence: PersistenceHandling, settingsManager: SettingsManaging) {
        self.persistence = persistence
        self.settingsManager = settingsManager
        
        // Load the initial snoozed list
        self.internalSnoozedTickers = Set(persistence.load(for: .snoozedTickers) ?? [])
        
        // Save the list whenever it changes
        $internalSnoozedTickers
            .dropFirst()
            .sink { [weak self] updatedList in
                self?.persistence.save(value: Array(updatedList), for: .snoozedTickers)
            }
            .store(in: &cancellables)
            
        // Listen for changes to the snooze clear time in settings
        settingsManager.settingsPublisher
            .map { $0.snoozeClearTime }
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.scheduleNextSnoozeClear()
            }
            .store(in: &cancellables)
    }

    func setSnooze(for ticker: String, isSnoozed: Bool) {
        if (isSnoozed){
            internalSnoozedTickers.insert(ticker)
        } else {
            internalSnoozedTickers.remove(ticker)
        }
    }
    
    func isSnoozed(ticker: String) -> Bool {
        internalSnoozedTickers.contains(ticker)
    }

    @objc func clearSnoozeList() {
#if DEBUG
        print("[Snooze] Snooze list cleared.")
#endif
        internalSnoozedTickers.removeAll()
        // Save the clear date to prevent clearing again until the next scheduled time
        persistence.save(value: Date(), for: .lastSnoozeClearDate)
        scheduleNextSnoozeClear()
    }
    
    private func scheduleNextSnoozeClear() {
        snoozeClearTimer?.invalidate()
        let calendar = Calendar.current
        let clearTime = settingsManager.currentSettings.snoozeClearTime
        let clearComponents = calendar.dateComponents([.hour, .minute], from: clearTime)
        
        guard let nextClearDate = calendar.nextDate(after: Date(), matching: clearComponents, matchingPolicy: .nextTime) else {
            return
        }
#if DEBUG
        print("[Snooze] Next snooze clear scheduled for \(nextClearDate.formatted(date: .long, time: .standard))")
#endif
        snoozeClearTimer = Timer.scheduledTimer(
            timeInterval: nextClearDate.timeIntervalSinceNow,
            target: self,
            selector: #selector(clearSnoozeList),
            userInfo: nil,
            repeats: false
        )
    }
    
}
