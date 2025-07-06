import SwiftUI

/// A generic, reusable calendar view that works with any object conforming to `MonthlyHistoryProvider`.
struct CalendarView<Provider: MonthlyHistoryProvider>: View {
    
    /// The display mode determines how dates without entries are handled.
    enum DisplayMode {
        /// Highlights days with entries but keeps all days enabled.
        case highlight
        /// Disables days without entries, except for today.
        case enableWithEntry
    }
    
    // The ViewModel is now an ObservedObject conforming to our generic provider protocol.
    @ObservedObject var provider: Provider
    let displayMode: DisplayMode

    private var calendar: Calendar { Calendar.current }
    
    // The displayed month is now managed by the provider, but we use a local
    // state to prevent the popover from closing when the month changes.
    @State private var displayedMonth: Date

    init(provider: Provider, displayMode: DisplayMode) {
        self.provider = provider
        self.displayMode = displayMode
        self._displayedMonth = State(initialValue: provider.displayedMonth)
    }

    var body: some View {
        VStack {
            CalendarHeaderView(
                displayedMonth: $displayedMonth,
                goToToday: provider.goToToday
            )
            
            HStack(spacing: 0) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(daysForDisplayedMonth(), id: \.self) { date in
                    // Use Calendar.compare to correctly check for the same month.
                    if calendar.compare(date, to: displayedMonth, toGranularity: .month) == .orderedSame {
                        
                        let hasEntry = provider.datesWithEntry.contains { calendar.isDate($0, inSameDayAs: date) }
                        let isToday = calendar.isDateInToday(date)
                        
                        // Determine if the day should be enabled based on the display mode.
                        let isEnabled = displayMode == .enableWithEntry ? hasEntry || isToday : true
                        
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: provider.selectedDate),
                            hasEntry: hasEntry,
                            isEnabled: isEnabled
                        )
                        .onTapGesture {
                            if isEnabled {
                                provider.selectedDate = date
                            }
                        }
                    } else {
                        Rectangle().fill(Color.clear)
                    }
                }
            }
        }
        .padding()
        .frame(width: 320)
        // When the displayed month in this view changes, update the provider.
        .onChange(of: displayedMonth) { _, newMonth in
            provider.displayedMonth = newMonth
        }
    }
    
    private func daysForDisplayedMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else { return [] }
        
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
    @Binding var displayedMonth: Date
    let goToToday: () -> Void
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter(); formatter.dateFormat = "MMMM yyyy"; return formatter
    }

    var body: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) { Image(systemName: "chevron.left") }
            Spacer()
            Text(monthYearFormatter.string(from: displayedMonth)).font(.headline)
            Spacer()
            Button(action: { changeMonth(by: 1) }) { Image(systemName: "chevron.right") }
        }
        .buttonStyle(.plain)
        .padding(.bottom, 10)
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}

private struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasEntry: Bool
    let isEnabled: Bool
    
    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayFormatter.string(from: date))
                .font(.system(size: 14)).fontWeight(.medium)
                .frame(maxWidth: .infinity).padding(6)
                .background(isSelected && isEnabled ? Color.accentColor : .clear)
                .clipShape(Circle())
                .overlay(isToday && isEnabled ? Circle().stroke(Color.secondary, lineWidth: 1.5) : nil)
                .foregroundColor(textColor)
            
            if hasEntry {
                Circle().fill(isEnabled ? Color.accentColor : Color.gray).frame(width: 5, height: 5)
            } else {
                Spacer().frame(height: 5)
            }
        }
        .opacity(isEnabled ? 1.0 : 0.4)
    }
    
    private var textColor: Color {
        if isSelected && isEnabled { return .white }
        return isEnabled ? .primary : .secondary
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter(); formatter.dateFormat = "d"; return formatter
    }
}
