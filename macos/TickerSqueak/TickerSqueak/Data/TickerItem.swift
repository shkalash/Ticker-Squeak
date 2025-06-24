import Foundation

struct TickerItem: Identifiable, Codable, Equatable {
    enum Direction: String, Codable {
        case none
        case bullish
        case bearish
    }

    let id = UUID()
    let ticker: String
    let receivedAt: Date
    
    /// Indicates if the user has starred this item for importance.
    var isStarred: Bool = false
    
    /// Indicates if the item has been seen by the user. Defaults to true for new items.
    var isUnread: Bool = true
    
    var direction: Direction = .none
}
