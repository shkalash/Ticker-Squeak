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
            // Starred filter
            if viewModel.showStarredOnly && !item.isStarred {
                return false
            }
            
            // Unread filter
            if viewModel.showUnreadOnly && !item.isUnread {
                return false
            }

            // Direction filters
            switch item.direction {
            case .bullish where !viewModel.showBullish:
                return false
            case .bearish where !viewModel.showBearish:
                return false
            default:
                return true
            }
        }
    }


    var body: some View {
        VStack {
            HStack {
                // --- Unread Filter Button with Integrated Count ---
                Button(action: {
                    viewModel.showUnreadOnly.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(viewModel.showUnreadOnly ? .blue : .secondary)
                        if viewModel.unreadCount > 0 {
                            Text("\(viewModel.unreadCount)")
                                .font(.callout)
                                
                        }
                    }
                }
                .foregroundColor(viewModel.showUnreadOnly ? .blue : .gray)
                .buttonStyle(.bordered)
                
                // --- Starred Filter Button ---
                Button(action: {
                    viewModel.showStarredOnly.toggle()
                }) {
                    Image(systemName: viewModel.showStarredOnly ? "star.fill" : "star.slash.fill")
                        .foregroundColor(viewModel.showStarredOnly ? .yellow : .gray)
                }
                .buttonStyle(.bordered)
                
                // --- Other Filter Buttons (unchanged) ---
                Button(action: { viewModel.showBullish.toggle() }) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(viewModel.showBullish ? .green : .gray)
                }
                .buttonStyle(.bordered)
                
                Button(action: { viewModel.showBearish.toggle() }) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .foregroundColor(viewModel.showBearish ? .red : .gray)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    if (!viewModel.showBullish && !viewModel.showBearish){
                        viewModel.showBullish = true
                        viewModel.showBearish = true
                    } else {
                        viewModel.showBullish = false
                        viewModel.showBearish = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Image(systemName: "chart.line.downtrend.xyaxis")
                    }
                }
                .buttonStyle(.bordered)
                .foregroundColor(.primary)
                
                Button(action: { viewModel.muteNotifications.toggle() }) {
                    Image(systemName: viewModel.muteNotifications ? "speaker.slash" : "speaker.wave.3")
                }
                .frame(width: 25)
                .buttonStyle(.bordered)
                .padding(.horizontal)
                
                Spacer()
                
                Button(action : { viewModel.clearTickers() }) {
                    Image(systemName: "trash")
                }
            }
            .padding([.leading, .trailing, .top])

            List(filteredTickers) { item in
                HStack {
                    // Unread indicator dot has been removed.
                    
                    Button(action: {
                        viewModel.toggleStarred(item)
                    }) {
                        Image(systemName: item.isStarred ? "star.fill" : "star.slash.fill")
                            .foregroundColor(item.isStarred ? .yellow : .gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    DirectionButton(item: Binding(
                        get: { item },
                        set: { viewModel.updateItem($0) }
                    ))
                    
                    Button(action: {
                        // Mark as read when clicked
                        viewModel.markAsRead(item)
                        self.onClick(item.ticker)
                    }) {
                        HStack {
                            Text(item.ticker)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(item.isStarred ? .primary : .secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    // --- Button order changed ---
                    Button(action: { viewModel.hideTicker(item) }) {
                        Image(systemName: "timer")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    Text((item.receivedAt.formatted(date: .omitted, time: .shortened)))
                        
                    Button(action: { viewModel.addToIgnore(item.ticker) }) {
                        Image(systemName: "eye.slash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.vertical, 4)
                // --- Highlight logic changed to use isUnread ---
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
