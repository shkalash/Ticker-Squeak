//
//  UserNotificationHandling.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//
import Combine
import UserNotifications

protocol NotificationHandling {
    var authorizationStatus: AnyPublisher<UNAuthorizationStatus, Never> { get }
    func requestPermission()
    func showNotification(for ticker: String, isHighPriority: Bool)
}

// MARK: - Notification Action Definitions
extension NotificationHandling {
    var openChartAction: UNNotificationAction {
        UNNotificationAction(
            identifier: TickerNotificationAction.openChart,
            title: "Open Chart",
            options: []
        )
    }
    /*
     Had an idea to have this also from notifications
     but this makes the notifcation have a drop down
     which makes the flow slower. can add this as config option in the future
    */
    /*var snoozeAction: UNNotificationAction {
        UNNotificationAction(
            identifier: TickerNotificationAction.snooze,
            title: "Snooze",
            options: []
        )
    }*/
    
    var allActions: [UNNotificationAction] {
        [openChartAction/*, snoozeAction*/]
    }
}

// MARK: - Action Identifiers and Keys
enum TickerNotificationAction {
    static let openChart = "OPEN_CHART"
    static let snooze = "SNOOZE_TICKER"
    static let categoryIdentifier = "TICKER_ALERT"
    static let tickerUserInfoKey = "ticker"
}
