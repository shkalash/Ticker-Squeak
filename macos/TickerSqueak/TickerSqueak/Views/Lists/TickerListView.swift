import SwiftUI

// The main, internal content view for the ticker list.
struct TickerListView_Content: View {
    
    @StateObject private var viewModel: TickerListViewModel
    
    /// The action to perform when a ticker symbol is clicked.
    private let onTickerClicked: (String) -> Void
    private let onOpenTradeIdea: (String) -> Void
    
    init(dependencies: any AppDependencies, onTickerClicked: @escaping (String) -> Void, onOpenTradeIdea: @escaping (String) -> Void) {
            self.onTickerClicked = onTickerClicked
            self.onOpenTradeIdea = onOpenTradeIdea
            _viewModel = StateObject(wrappedValue: TickerListViewModel(dependencies: dependencies))
        }

    var body: some View {
        VStack(spacing: 0) {
            // Main filter and action toolbar
            // And Multi selection tools. Adapts to fit the multiple selection tools if possible
            AdaptiveToolbarContainer(viewModel: viewModel)
            // The main list of tickers
            List(selection: $viewModel.selection) {
                ForEach(viewModel.visibleTickers) { item in
                    TickerListRow(
                        item: item,
                        onTickerClicked: {
                            viewModel.markAsRead(id: item.id)
                            onTickerClicked(item.ticker)
                        },
                        onToggleUnread: { viewModel.toggleUnread(id: item.id) },
                        onToggleStarred: { viewModel.toggleStarred(id: item.id) },
                        onHide: { viewModel.hideTicker(id: item.id) },
                        onSnooze: { viewModel.snoozeTicker(id: item.id) },
                        onIgnore: { viewModel.addToIgnoreList(ticker: item.ticker)},
                        onUpdateDirection: { newDirection in
                            viewModel.updateDirection(id: item.id, direction: newDirection)},
                        onOpenTradeIdea: {
                            // Call the ViewModel to perform the actions...
                            viewModel.createAndOpenTradeIdea(id: item.id)
                            // ...then call the closure to trigger navigation.
                            onOpenTradeIdea(item.ticker)
                        }
                    )
                    .listRowBackground(viewModel.selection.contains(item.id) ? Color.yellow.opacity(0.4) : (item.isUnread ? Color.blue.opacity(0.1) : Color.clear))
                    .tag(item.id) // Required for selection to work
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }
}


struct AdaptiveToolbarContainer: View {
    @ObservedObject var viewModel: TickerListViewModel

    var body: some View {
        ViewThatFits(in: .horizontal) {
            // Attempt 1: The ideal single-line layout
            HStack() {
                TickerListToolbar(viewModel: viewModel)
                Spacer(minLength: 3)
                SelectionToolbar(viewModel: viewModel)
                Spacer(minLength: 3)
                TickerListToolbarTrailing(viewModel: viewModel)
            }
            
            // Attempt 2: The fallback two-line layout
            VStack(spacing: 0) {
                HStack{
                    TickerListToolbar(viewModel: viewModel)
                    Spacer(minLength: 5)
                    TickerListToolbarTrailing(viewModel: viewModel)
                }
                SelectionToolbar(viewModel: viewModel)
            }
        }.padding(.top, 8)
    }
}


/// The public-facing "loader" view.
struct TickerListView: View {
    @EnvironmentObject private var dependencies: DependencyContainer
    private let onTickerClicked: (String) -> Void
    private let onOpenTradeIdea: (String) -> Void
    init(onTickerClicked: @escaping (String) -> Void,
         onOpenTradeIdea: @escaping (String) -> Void) {
        self.onTickerClicked = onTickerClicked
        self.onOpenTradeIdea = onOpenTradeIdea
    }

    var body: some View {
        TickerListView_Content(dependencies: dependencies, onTickerClicked: onTickerClicked , onOpenTradeIdea: onOpenTradeIdea)
    }
}


// MARK: - Subviews for TickerListView_Content

private struct TickerListToolbar: View {
    @ObservedObject var viewModel: TickerListViewModel
    @Environment(\.openWindow) private var openWindow
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
            
            Button(action:{
                openWindow(id: "floating-spy")
            }, label : {
                Image("oneoption")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20 , height: 20)
            })
           
        }
        .padding(.leading)
        .buttonStyle(.bordered)
    }
        
}

private struct TickerListToolbarTrailing: View {
    @ObservedObject var viewModel: TickerListViewModel
    var body: some View {
        HStack{
            // --- Global Action Buttons ---
            Button(action: { viewModel.setMute(!viewModel.appSettings.isMuted) }) {
                Image(systemName: viewModel.appSettings.isMuted ? "speaker.slash" : "speaker.wave.3")
                    .frame(width: 20)
            }
            .help("Toggle Sound")
            
            Button(action: viewModel.clearAllTickers) {
                Image(systemName: "trash")
            }.help("Clear All Tickers")
        }.padding(.trailing)
    }
}

private struct SelectionToolbar: View {
    @ObservedObject var viewModel: TickerListViewModel
    var body: some View {
        HStack() {
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
                            onSetBullish: {viewModel.performActionOnSelection(.setBullish)},
                            onSetBearish: {viewModel.performActionOnSelection(.setBearish)},
                            onSetNeutral: {viewModel.performActionOnSelection(.setNeutral)}
            )
        }
        .disabled(viewModel.selection.isEmpty)
        .opacity(viewModel.selection.isEmpty ? 0.5 : 1.0)
    }
}


private struct TickerListRow: View {
    let item: TickerItem
    let onTickerClicked: () -> Void
    let onToggleUnread: () -> Void
    let onToggleStarred: () -> Void
    let onHide: () -> Void
    let onSnooze: () -> Void
    let onIgnore: () -> Void
    let onUpdateDirection: (TickerItem.Direction) -> Void
    let onOpenTradeIdea: () -> Void
    // TODO: scroll position needs to move maybe when removing filter?
    var body: some View {
        HStack {
            ActionButton(systemImage: item.isUnread ? "circle.fill" : "circle", color: item.isUnread ? .white : .gray.opacity(0.4), help: "Toggle Read", action: onToggleUnread)
            ActionButton(systemImage: item.isStarred ? "star.fill" : "star", color: item.isStarred ? .yellow : .gray, help: "Toggle Star", action: onToggleStarred)
            
            Button(action: onTickerClicked) {
                Text(item.ticker)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(item.isUnread ? .bold : .regular)
            }
            .buttonStyle(.plain)
            .frame(width: 45)
            
            DirectionButton(
                direction: item.direction,
                onSetBullish: {
                    // Tell the ViewModel to update the direction to bullish
                    onUpdateDirection(.bullish)
                },
                onSetBearish: {
                    // Tell the ViewModel to update the direction to bearish
                    onUpdateDirection(.bearish)
                },
                onSetNeutral: {
                    onUpdateDirection(.none)
                }
                
            )
            
            ActionButton(systemImage: "lightbulb.fill", color: .yellow, help: "Create/View Trade Idea", action: onOpenTradeIdea).padding(.leading)
            
            Spacer()
            ActionButton(systemImage: "timer", help: "Hide", action: onHide)
            
            Text(item.receivedAt.formatted(date: .omitted, time: .shortened))
                .frame(minWidth : 40)
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
    
    return TickerListView_Content(dependencies: previewDependencies, onTickerClicked: { ticker in
        print("Symbol clicked: \(ticker)")
    } , onOpenTradeIdea: { ticker in })
    .environmentObject(previewDependencies)
    .frame(width: 600, height: 700)
}
