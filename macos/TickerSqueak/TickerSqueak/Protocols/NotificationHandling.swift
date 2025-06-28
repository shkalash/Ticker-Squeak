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
