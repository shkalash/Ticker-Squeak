import SwiftUI

// The main, internal content view for the ticker list.
struct TickerListView_Content: View {
    
    @StateObject private var viewModel: TickerListViewModel
    
    /// The action to perform when a ticker symbol is clicked.
    private let onSymbolClicked: (String) -> Void

    init(dependencies: any AppDependencies, onSymbolClicked: @escaping (String) -> Void) {
        self.onSymbolClicked = onSymbolClicked
        _viewModel = StateObject(wrappedValue: TickerListViewModel(dependencies: dependencies))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main filter and action toolbar
            TickerListToolbar(viewModel: viewModel)

            // The main list of tickers
            List(selection: $viewModel.selection) {
                ForEach(viewModel.visibleTickers) { item in
                    TickerListRow(
                        item: item,
                        onSymbolClicked: {
                            viewModel.markAsRead(id: item.id)
                            onSymbolClicked(item.ticker)
                        },
                        onToggleUnread: { viewModel.toggleUnread(id: item.id) },
                        onToggleStarred: { viewModel.toggleStarred(id: item.id) },
                        onHide: { viewModel.hideTicker(id: item.id) },
                        onSnooze: { viewModel.snoozeTicker(id: item.id) },
                        onIgnore: { viewModel.addToIgnoreList(ticker: item.ticker)},
                        onUpdateDirection: { newDirection in
                            viewModel.updateDirection(id: item.id, direction: newDirection)}
                    )
                    .listRowBackground(viewModel.selection.contains(item.id) ? Color.yellow.opacity(0.4) : (item.isUnread ? Color.blue.opacity(0.1) : Color.clear))
                    .tag(item.id) // Required for selection to work
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .animation(.spring, value: viewModel.selection.isEmpty)
        }
    }
}


/// The public-facing "loader" view.
struct TickerListView: View {
    @EnvironmentObject private var dependencies: DependencyContainer
    private let onSymbolClicked: (String) -> Void

    init(onSymbolClicked: @escaping (String) -> Void) {
        self.onSymbolClicked = onSymbolClicked
    }

    var body: some View {
        TickerListView_Content(dependencies: dependencies, onSymbolClicked: onSymbolClicked)
    }
}


// MARK: - Subviews for TickerListView_Content

private struct TickerListToolbar: View {
    @ObservedObject var viewModel: TickerListViewModel
    var body: some View {
        HStack {
            // --- Filter Buttons ---
            Button {
                viewModel.setFilter(showUnread: !viewModel.appSettings.showUnread)
            } label: {
                
                HStack{
                    Image(systemName: "envelope.fill")
                        .foregroundColor(viewModel.appSettings.showUnread ? .white : .gray)
                    Spacer()
                    Text("\(viewModel.unreadCount)").font(.caption)
                        .foregroundColor(.secondary)
                }.frame(width: 47,alignment: .leading)
            }
            
            .help("Filter Unread")
            
            FilterButton(isOn: viewModel.appSettings.showStarred, systemImage: "star.fill", onColor: .yellow, help: "Filter Starred") {
                viewModel.setFilter(showStarred: !viewModel.appSettings.showStarred)
            }
            
            FilterButton(isOn: viewModel.appSettings.showBullish, systemImage: "chart.line.uptrend.xyaxis", onColor: .green, help: "Show Bullish") {
                viewModel.setFilter(showBullish: !viewModel.appSettings.showBullish)
            }
            
            FilterButton(isOn: viewModel.appSettings.showBearish, systemImage: "chart.line.downtrend.xyaxis", onColor: .red, help: "Show Bearish") {
                viewModel.setFilter(showBearish: !viewModel.appSettings.showBearish)
            }
            
            Button(action: {
                if (!viewModel.appSettings.showBullish && !viewModel.appSettings.showBearish){
                    viewModel.setFilter(showBearish: true)
                    viewModel.setFilter(showBullish: true)
                } else {
                    viewModel.setFilter(showBearish: false)
                    viewModel.setFilter(showBullish: false)
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
            
            SelectionToolbar(viewModel: viewModel)
           .frame(height: 20)
           .opacity(viewModel.selection.count > 1  ? 1 : 0)
           .clipped()
            Spacer()
            
            // --- Global Action Buttons ---
            Button(action: { viewModel.setMute(!viewModel.appSettings.isMuted) }) {
                Image(systemName: viewModel.appSettings.isMuted ? "speaker.slash" : "speaker.wave.3")
                    .frame(width: 20)
            }
            .help("Toggle Sound")
            
            Button(action: viewModel.clearAllTickers) {
                Image(systemName: "trash")
            }.help("Clear All Tickers")
        }
        .padding()
        .buttonStyle(.bordered)
    }
        
}

private struct SelectionToolbar: View {
    @ObservedObject var viewModel: TickerListViewModel
    var body: some View {
        HStack {
            Text("\(viewModel.selection.count) selected").font(.headline).padding(.horizontal)
            ActionButton(systemImage: "envelope.open", color: .white, help: "Toggle Read") { viewModel.performActionOnSelection(.toggleRead) }
            ActionButton(systemImage: "star", color: .yellow, help: "Toggle Star") { viewModel.performActionOnSelection(.toggleStar) }
            ActionButton(systemImage: "timer", help: "Hide Temporarily") { viewModel.performActionOnSelection(.hide) }
            ActionButton(systemImage: "moon", color : .orange, help: "Snooze Selection") { viewModel.performActionOnSelection(.snooze) }
            ActionButton(systemImage: "eye.slash", color: .red, help: "Ignore Selection") { viewModel.performActionOnSelection(.ignore) }
            DirectionButton(direction: .none,
                            style: DirectionButtonStyle(
                                    frame: CGSize(width: 48, height: 28),
                                    backgroundColor: .clear,
                                    cornerRadius: 1,
                                    noneDirectionStyle: .upAndDown),
                            onLeftClick: {viewModel.performActionOnSelection(.setBullish)},
                            onRightClick: {viewModel.performActionOnSelection(.setBearish)},
                            onMiddleClick: {viewModel.performActionOnSelection(.setNeutral)}
            )
        }
        .padding(.horizontal)
    }
}


private struct TickerListRow: View {
    let item: TickerItem
    let onSymbolClicked: () -> Void
    let onToggleUnread: () -> Void
    let onToggleStarred: () -> Void
    let onHide: () -> Void
    let onSnooze: () -> Void
    let onIgnore: () -> Void
    let onUpdateDirection: (TickerItem.Direction) -> Void
    // TODO: scroll position needs to move maybe when removing filter?
    var body: some View {
        HStack {
            ActionButton(systemImage: item.isUnread ? "circle.fill" : "circle", color: item.isUnread ? .white : .gray.opacity(0.4), help: "Toggle Read", action: onToggleUnread)
            ActionButton(systemImage: item.isStarred ? "star.fill" : "star", color: item.isStarred ? .yellow : .gray, help: "Toggle Star", action: onToggleStarred)
            
            Button(action: onSymbolClicked) {
                Text(item.ticker)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(item.isUnread ? .bold : .regular)
            }
            .buttonStyle(.plain)
            .frame(width: 45)
            
            DirectionButton(
                direction: item.direction,
                onLeftClick: {
                    // Tell the ViewModel to update the direction to bullish
                    onUpdateDirection(.bullish)
                },
                onRightClick: {
                    // Tell the ViewModel to update the direction to bearish
                    onUpdateDirection(.bearish)
                },
                onMiddleClick: {
                    onUpdateDirection(.none)
                }
            )
            
            Spacer()
            ActionButton(systemImage: "timer", help: "Hide", action: onHide)
            
            Text(item.receivedAt.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
            
            ActionButton(systemImage: "moon.fill", color: .orange, help: "Snooze" , action: onSnooze)
            ActionButton(systemImage: "eye.slash", color: .red, help: "Ignore", action: onIgnore)
        }
        .padding(.vertical, 4)
    }
}


// MARK: - Reusable Button Components

private struct FilterButton: View {
    let isOn: Bool
    let systemImage: String
    var onColor: Color = .accentColor
    var offColor: Color = .secondary
    let help: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .foregroundColor(isOn ? onColor : offColor)
        }
        .help(help)
    }
}

private struct ActionButton: View {
    var title: String? = nil
    let systemImage: String
    var color: Color = .accentColor
    let help: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if let title = title {
                Label(title, systemImage: systemImage)
            } else {
                Image(systemName: systemImage)
            }
        }
        .foregroundColor(color)
        .buttonStyle(.borderless)
        .help(help)
    }
}


#Preview {
    let previewDependencies = PreviewDependencyContainer()
    
    return TickerListView_Content(dependencies: previewDependencies, onSymbolClicked: { ticker in
        print("Symbol clicked: \(ticker)")
    })
    .environmentObject(previewDependencies)
    .frame(width: 600, height: 700)
}
