import Foundation
import SwiftUI
import Combine

struct StockItem: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let code: String
    let market: String
    let price: String
    let change: Double

    init(id: UUID = UUID(), name: String, code: String, market: String, price: String, change: Double) {
        self.id = id
        self.name = name
        self.code = code
        self.market = market
        self.price = price
        self.change = change
    }
}

@MainActor
final class StockManager: ObservableObject {
    @Published var selectedStock: StockItem? = nil
    @Published var stocks: [StockItem] = []
    
    private let filename = "stocks.json"
    
    init() {
        loadStocks()
    }
    
    private var fileURL: URL {
        let manager = FileManager.default
        let documents = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent(filename)
    }
    
    private func loadStocks() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([StockItem].self, from: data)
            self.stocks = decoded
        } catch {
            print(error)
            self.stocks = []
            saveStocks()
        }
    }
    
    private func saveStocks() {
        do {
            let data = try JSONEncoder().encode(stocks)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("nie")
        }
    }
    
    func removeStock(_ stock: StockItem) {
        stocks.removeAll { $0.id == stock.id }
        saveStocks()
    }
    
    func addStock(symbol: String, market: String = "NASDAQ") async {
            do {
                let quote = try await SwiftStockAPI.shared.fetchQuote(for: symbol)
                let newStock = StockItem(
                    name: symbol,
                    code: symbol,
                    market: market,
                    price: String(format: "%.2f", quote.current),
                    change: quote.percentChange
                )
                stocks.append(newStock)
                saveStocks()
                print("Added \(symbol) with price \(quote.current)")
            } catch {
                print("Error fetching stock quote for \(symbol): \(error)")
            }
        }
    
    func refreshAllStocks() async {
            for (index, stock) in stocks.enumerated() {
                do {
                    let quote = try await SwiftStockAPI.shared.fetchQuote(for: stock.code)
                    stocks[index] = StockItem(
                        id: stock.id,
                        name: stock.name,
                        code: stock.code,
                        market: stock.market,
                        price: String(format: "%.2f", quote.current),
                        change: quote.percentChange
                    )
                } catch {
                    print("⚠️ Failed to refresh \(stock.code): \(error)")
                }
            }
            saveStocks()
            print("🔁 All stocks refreshed.")
        }
}
