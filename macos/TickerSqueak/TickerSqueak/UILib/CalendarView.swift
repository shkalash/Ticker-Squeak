//
//  CalendarView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/6/25.
//


import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    @ObservedObject var viewModel: TradeIdeasListViewModel

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        VStack {
            CalendarHeaderView(viewModel: viewModel)
            // Day of the week headers
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            // The grid of days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(daysForDisplayedMonth(), id: \.self) { date in
                    if calendar.compare(date, to: viewModel.displayedMonth, toGranularity: .month) == .orderedSame {
                        CalendarDayView(
                            date: date,
                            isSelected: isSelected(date),
                            hasIdeas: hasIdeas(date)
                        )
                        .onTapGesture { selectedDate = date }
                    } else {
                        // Fill grid with blank views for days not in the current month
                        Rectangle().fill(Color.clear)
                    }
                }
            }
        }
        .padding()
        .frame(width: 320)
    }
    
    // MARK: - Helper Functions
    
    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    private func hasIdeas(_ date: Date) -> Bool {
        viewModel.datesWithIdeas.contains { calendar.isDate($0, inSameDayAs: date) }
    }
    
    private func daysForDisplayedMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: viewModel.displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = monthFirstWeek.start
        while currentDate < monthLastWeek.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return days
    }
}

// MARK: - Subviews

private struct CalendarHeaderView: View {
    @ObservedObject var viewModel: TradeIdeasListViewModel
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }

    var body: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Spacer()
            Text(monthYearFormatter.string(from: viewModel.displayedMonth))
                .font(.headline)
            Spacer()

            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 10)
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: viewModel.displayedMonth) {
            viewModel.displayedMonth = newMonth
        }
    }
}

private struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasIdeas: Bool
    
    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayFormatter.string(from: date))
                .font(.system(size: 14))
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(isSelected ? Color.accentColor : (isToday ? Color.secondary.opacity(0.3) : Color.clear))
                .clipShape(Circle())
                .foregroundColor(isSelected || isToday ? .white : .primary)
            
            // The "bonus point" dot for days with ideas
            if hasIdeas {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 5, height: 5)
            } else {
                // Keep space consistent
                Spacer().frame(height: 5)
            }
        }
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
}
