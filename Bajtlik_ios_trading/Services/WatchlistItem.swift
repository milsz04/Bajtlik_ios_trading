import Foundation
import SwiftData

@Model
final class WatchlistItem {
    @Attribute(.unique) var id: UUID

    var name: String
    var code: String

    var current: Double
    var change: Double
    var percentChange: Double
    var high: Double
    var low: Double
    var open: Double
    var previousClose: Double

    init(
        id: UUID = UUID(),
        name: String,
        code: String,
        current: Double,
        change: Double,
        percentChange: Double,
        high: Double,
        low: Double,
        open: Double,
        previousClose: Double
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.current = current
        self.change = change
        self.percentChange = percentChange
        self.high = high
        self.low = low
        self.open = open
        self.previousClose = previousClose
    }
}

