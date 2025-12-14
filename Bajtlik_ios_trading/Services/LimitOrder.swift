import Foundation
import SwiftData

@Model
final class LimitOrder {
    @Attribute(.unique) var id: UUID

    var symbol: String
    var name: String
    var side: String

    var shares: Double
    var limitPrice: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        side: String,
        shares: Double,
        limitPrice: Double,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.side = side
        self.shares = shares
        self.limitPrice = limitPrice
        self.createdAt = createdAt
    }
}

