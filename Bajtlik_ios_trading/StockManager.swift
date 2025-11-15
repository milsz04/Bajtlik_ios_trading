import Foundation
import SwiftUI
import Combine

struct StockItem: Identifiable, Hashable, Codable {
    let id: UUID
    
    let name: String
    let code: String
    
    let current: Double        // c
    let change: Double         // d
    let percentChange: Double  // dp
    let high: Double           // h
    let low: Double            // l
    let open: Double           // o
    let previousClose: Double  // pc
    
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

@MainActor
final class StockManager: ObservableObject {
    @Published var selectedStock: StockItem? = nil
    @Published var stocks: [StockItem] = []
    
    private let filename = "stocks.json"
    
    init() {
        loadStocks()
    }
    
    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(filename)
    }
    
    private func loadStocks() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([StockItem].self, from: data)
            self.stocks = decoded
        } catch {
            print("No JSON found, creating fresh file.")
            self.stocks = []
            saveStocks()
        }
    }
    
    private func saveStocks() {
        do {
            let data = try JSONEncoder().encode(stocks)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save stocks:", error)
        }
    }
    
    func removeStock(_ stock: StockItem) {
        stocks.removeAll { $0.id == stock.id }
        saveStocks()
    }
    
    func addStock(symbol: String) async {
        do {
            let quote = try await SwiftStockAPI.shared.fetchQuote(for: symbol)

            let newStock = StockItem(
                name: symbol,
                code: symbol,
                current: quote.current,
                change: quote.change,
                percentChange: quote.percentChange,
                high: quote.high,
                low: quote.low,
                open: quote.open,
                previousClose: quote.previousClose
            )

            stocks.append(newStock)
            saveStocks()
            print("Added \(symbol). Current price: \(quote.current)")
        } catch {
            print("Error fetching quote for \(symbol):", error)
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
                    current: quote.current,
                    change: quote.change,
                    percentChange: quote.percentChange,
                    high: quote.high,
                    low: quote.low,
                    open: quote.open,
                    previousClose: quote.previousClose
                )
                
            } catch {
                print("Failed to refresh \(stock.code):", error)
            }
        }
        
        saveStocks()
        print("All stocks refreshed.")
    }
}

