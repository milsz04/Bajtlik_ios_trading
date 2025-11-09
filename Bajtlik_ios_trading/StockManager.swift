import Foundation
import SwiftUI
import Combine

struct StockItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    let market: String
    let price: String
    let change: Double
}

final class StockManager: ObservableObject {
    @Published var selectedStock: StockItem? = nil
    @Published var stocks: [StockItem] = [
        StockItem(name: "Allegro",code: "AGR", market: "GPW", price: "33,41", change: 0.67),
        StockItem(name: "Apple", code: "AAPL", market: "NASDAQ", price: "120.55", change: -1.2),
        StockItem(name: "CDProject",code: "CDPR", market: "GPW", price: "159.90", change: 2.35),
        StockItem(name: "Test", code: "TEST", market: "GPW", price: "19.90", change: 2.05)
    ]
}
