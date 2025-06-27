import Foundation

struct TickerPayload: Decodable {
    
    let ticker: String
    let isHighPriority: Bool
    
    private enum CodingKeys: String, CodingKey {
        case ticker
        case highPriority
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode the raw ticker and then apply the uppercase transformation.
        let tickerRaw = try container.decode(String.self, forKey: .ticker)
        self.ticker = tickerRaw.uppercased()
        
        // Decode the `highPriority` key only if it's present in the JSON.
        // If it's missing (`nil`), default to `false`.
        self.isHighPriority = try container.decodeIfPresent(Bool.self, forKey: .highPriority) ?? false
    }
}
