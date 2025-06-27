//
//  UserNotificationHandling.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//
import Combine
import UserNotifications

protocol NotificationHandling {
    /// A publisher that emits toast messages for the UI to display.
    var toastPublisher: PassthroughSubject<Toast, Never> { get }
    var authorizationStatus: AnyPublisher<UNAuthorizationStatus, Never> { get }
    func requestPermission()
    func showNotification(for ticker: String, isHighPriority: Bool)
}
