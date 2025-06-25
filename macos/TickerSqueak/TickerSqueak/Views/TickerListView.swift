import SwiftUI

struct TickerListView: View {
    @ObservedObject var viewModel: TickerSqueakViewModel
    private let onClick: (String) -> Void

    init(viewModel: TickerSqueakViewModel , onSymobolClicked: @escaping (String) -> Void) {
        self.onClick = onSymobolClicked
        self.viewModel = viewModel
    }
    
    var filteredTickers: [TickerItem] {
        viewModel.tickerList.filter { item in
            // First, apply direction filters as they are independent.
            let passesDirectionFilter: Bool
            switch item.direction {
            case .bullish where !viewModel.showBullish:
                passesDirectionFilter = false
            case .bearish where !viewModel.showBearish:
                passesDirectionFilter = false
            default:
                passesDirectionFilter = true
            }

            if !passesDirectionFilter {
                return false
            }

            // Next, apply the combined Unread/Starred filters.
            let aSpecialFilterIsOn = viewModel.showUnreadOnly || viewModel.showStarredOnly
            
            // If no special filters are on, the item passes.
            if !aSpecialFilterIsOn {
                return true
            }
            
            // If any special filter is on, check if the item meets the criteria.
            var passesSpecialFilter = false
            if viewModel.showUnreadOnly && item.isUnread {
                passesSpecialFilter = true
            }
            if viewModel.showStarredOnly && item.isStarred {
                passesSpecialFilter = true
            }
            
            return passesSpecialFilter
        }
    }


    var body: some View {
        VStack {
            HStack {
                // --- Unread Filter Button ---
                Button(action: {
                    viewModel.showUnreadOnly.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope.fill")
                        if viewModel.unreadCount > 0 {
                            Text("\(viewModel.unreadCount)")
                                .font(.callout)
                        }
                    }
                }
                .foregroundColor(viewModel.showUnreadOnly ? .blue : .secondary)
                .buttonStyle(.bordered)
                .help("Filter by Unread")

                // --- Starred Filter Button ---
                Button(action: {
                    viewModel.showStarredOnly.toggle()
                }) {
                    Image(systemName: viewModel.showStarredOnly ? "star.fill" : "star.slash.fill")
                        .foregroundColor(viewModel.showStarredOnly ? .yellow : .gray)
                }
                .buttonStyle(.bordered)
                .help("Filter by Starred")

                // --- Direction Filter Buttons ---
                Button(action: { viewModel.showBullish.toggle() }) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(viewModel.showBullish ? .green : .gray)
                }
                .buttonStyle(.bordered)
                .help("Show Bullish Tickers")
                
                Button(action: { viewModel.showBearish.toggle() }) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .foregroundColor(viewModel.showBearish ? .red : .gray)
                }
                .buttonStyle(.bordered)
                .help("Show Bearish Tickers")
                
                Button(action: {
                    if (!viewModel.showBullish && !viewModel.showBearish){
                        viewModel.showBullish = true; viewModel.showBearish = true
                    } else {
                        viewModel.showBullish = false; viewModel.showBearish = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Image(systemName: "chart.line.downtrend.xyaxis")
                    }
                }
                .buttonStyle(.bordered)
                .foregroundColor(.primary)
                .help("Toggle All Directions")
                
                Button(action: { viewModel.muteNotifications.toggle() }) {
                    Image(systemName: viewModel.muteNotifications ? "speaker.slash" : "speaker.wave.3")
                }
                .frame(width: 25)
                .buttonStyle(.bordered)
                .padding(.horizontal)
                .help("Toggle Sound")
                
                Spacer()
                
                // --- List Action Buttons ---
                Button(action: { viewModel.clearSnoozeList() }) {
                    Image(systemName: "moon")
                }
                .help("Clear snoozed tickers")

                Button(action : { viewModel.clearTickers() }) {
                    Image(systemName: "trash")
                }
                .help("Clear all tickers")
            }
            .padding([.leading, .trailing, .top])

            List(filteredTickers) { item in
                HStack {
                    // --- Row Action Buttons ---
                    Button(action: { viewModel.toggleUnread(item) }) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(item.isUnread ? .blue : Color.gray.opacity(0.4))
                    }
                    .buttonStyle(.borderless)
                    .help("Toggle Read Status")
                    
                    Button(action: { viewModel.toggleStarred(item) }) {
                        Image(systemName: item.isStarred ? "star.fill" : "star")
                            .foregroundColor(item.isStarred ? .yellow : .gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Toggle Star")
                    
                    DirectionButton(item: Binding( get: { item }, set: { viewModel.updateItem($0) } ))
                    
                    Button(action: {
                        viewModel.markAsRead(item)
                        self.onClick(item.ticker)
                    }) {
                        HStack {
                            Text(item.ticker)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(item.isUnread ? .bold : .regular)
                                .foregroundColor(item.isStarred ? .primary : .secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(action: { viewModel.hideTicker(item) }) {
                        Image(systemName: "timer")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Hide Temporarily")

                    Text((item.receivedAt.formatted(date: .omitted, time: .shortened)))
                        .font(.caption)
                    
                    Button(action: { viewModel.snoozeTicker(item) }) {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Snooze until end of day")

                    Button(action: { viewModel.addToIgnore(item.ticker) }) {
                        Image(systemName: "eye.slash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Ignore this ticker permanently")
                }
                .padding(.vertical, 4)
                .listRowBackground(item.isUnread ? Color.blue.opacity(0.15) : Color.clear)
            }
        }
    }
    
    func copyTicker(_ ticker: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(ticker, forType: .string)
        #endif
    }
}

#Preview {
    TickerListView(viewModel: TickerSqueakViewModel(), onSymobolClicked: { _ in })
}
