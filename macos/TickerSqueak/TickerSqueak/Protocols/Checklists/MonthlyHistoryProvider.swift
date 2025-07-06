//
//  MonthlyHistoryProvider.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/6/25.
//

import Foundation
@MainActor
/// Used as a proxy data structure for Calendar views
protocol MonthlyHistoryProvider : ObservableObject {
    var selectedDate: Date { get set }
    var datesWithEntry: Set<Date> { get }
    var displayedMonth: Date { get set }
    func goToToday()
}
