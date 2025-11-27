import Foundation
import SwiftUI
import SwiftData
import Combine

@Model
final class StockItem {
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


@MainActor
final class StockManager: ObservableObject {
    @Published var selectedStock: StockItem? = nil
    @Published var balance: Double = 10000.00
    
    init() {}
    
    func addStock(symbol: String, in context: ModelContext) async {
        do {
            let quote = try await SwiftStockAPI.shared.fetchQuote(for: symbol)
            let name = try await SwiftStockAPI.shared.fetchCompanyName(for: symbol)

            let newStock = StockItem(
                name: name,
                code: symbol,
                current: quote.current,
                change: quote.change,
                percentChange: quote.percentChange,
                high: quote.high,
                low: quote.low,
                open: quote.open,
                previousClose: quote.previousClose
            )

            context.insert(newStock)
            try context.save()
            print("Added \(symbol). Current price: \(quote.current)")
        } catch {
            print("Error fetching quote for \(symbol):", error)
        }
    }
    
    func removeStock(_ stock: StockItem, in context: ModelContext) {
        context.delete(stock)
        do {
            try context.save()
        } catch {
            print("Failed to remove stock:", error)
        }
    }
    
    func refreshAllStocks(stocks: [StockItem], in context: ModelContext) async {
        for stock in stocks {
            do {
                let quote = try await SwiftStockAPI.shared.fetchQuote(for: stock.code)

                stock.current = quote.current
                stock.change = quote.change
                stock.percentChange = quote.percentChange
                stock.high = quote.high
                stock.low = quote.low
                stock.open = quote.open
                stock.previousClose = quote.previousClose
                
            } catch {
                print("Failed to refresh \(stock.code):", error)
            }
        }
        
        do {
            try context.save()
            print("All stocks refreshed.")
        } catch {
            print("Failed to save refreshed stocks:", error)
        }
    }
}



