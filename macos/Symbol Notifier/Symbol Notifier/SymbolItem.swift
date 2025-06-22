
struct SymbolItem: Identifiable, Codable, Equatable {
    let id = UUID()
    let symbol: String
    let receivedAt: Date
    var isHighlighted: Bool = true
}
