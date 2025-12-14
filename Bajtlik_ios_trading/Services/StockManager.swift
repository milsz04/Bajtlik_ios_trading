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
    var sharesOwned: Double
    var avgCost: Double
    var costBasis: Double
    var marketValue: Double { sharesOwned * current }
    var unrealizedPL: Double { marketValue - costBasis }
    var unrealizedPLPercent: Double {
        guard costBasis > 0 else { return 0 }
        return (unrealizedPL / costBasis) * 100
    }


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
        previousClose: Double,
        sharesOwned: Double = 0.0,
        avgCost: Double = 0.0,
        costBasis: Double = 0.0
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
        self.sharesOwned = sharesOwned
        self.avgCost = avgCost
        self.costBasis = costBasis
    }
}

@MainActor
final class StockManager: ObservableObject {
    @Published var selectedStock: StockItem? = nil
    @Published var balance: Double = 10000.00
    @Published var selectedStockCode: String? = nil
    @Published var selectedStockPrice: Double? = nil
    @Published var selectedSymbol: String? = nil
    @Published var selectedName: String? = nil


    init() {}

    func addStock(query: String, in context: ModelContext) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            // Assume SwiftStockAPI is defined elsewhere and handles fetching/decoding
            let results = try await SwiftStockAPI.shared.searchStocks(matching: trimmed)

            let bestMatch = results.first(where: { ($0.type ?? "") == "Common Stock" }) ?? results.first

            guard let match = bestMatch else {
                print("No search results for: \(trimmed)")
                return
            }

            let symbol = match.symbol ?? match.displaySymbol ?? trimmed.uppercased()

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
            print("Added \(symbol) (\(trimmed)). Current price: \(quote.current)")
        } catch {
            print("Error adding stock for query '\(trimmed)':", error)
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
                // Assume SwiftStockAPI is defined elsewhere and handles fetching/decoding
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

    func tryBuy(shares: Double, pricePerShare: Double) -> Bool {
        let totalCost = shares * pricePerShare
        guard totalCost <= balance else {
            return false
        }
        balance -= totalCost
        return true
    }
    func addWatchlistStock(query: String, in context: ModelContext) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let results = try await SwiftStockAPI.shared.searchStocks(matching: trimmed)
            let bestMatch = results.first(where: { ($0.type ?? "") == "Common Stock" }) ?? results.first
            guard let match = bestMatch else { return }

            let symbol = match.symbol ?? match.displaySymbol ?? trimmed.uppercased()

            // prevent duplicates in watchlist
            let existing = try context.fetch(
                FetchDescriptor<WatchlistItem>(predicate: #Predicate { $0.code == symbol })
            ).first
            if existing != nil { return }

            let quote = try await SwiftStockAPI.shared.fetchQuote(for: symbol)
            let name = try await SwiftStockAPI.shared.fetchCompanyName(for: symbol)

            let newItem = WatchlistItem(
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

            context.insert(newItem)
            try context.save()
        } catch {
            print("Error adding watchlist stock:", error)
        }
    }
    func removeWatchlistStock(_ stock: WatchlistItem, in context: ModelContext) {
        context.delete(stock)
        do { try context.save() }
        catch { print("Failed to remove watchlist stock:", error) }
    }
    func select(stock: StockItem) {
        selectedStock = stock
        selectedSymbol = stock.code
        selectedName = stock.name
    }

    func select(watchlist: WatchlistItem) {
        selectedStock = nil                 // important: don’t point to portfolio model
        selectedSymbol = watchlist.code
        selectedName = watchlist.name
    }
    @MainActor
    func buyStock(symbol: String, in context: ModelContext, shares: Double, executionPrice: Double) async -> Bool {
        guard shares >= 0.01 else { return false }
        let totalCost = shares * executionPrice
        guard totalCost <= balance else { return false }

        do {
            // Find existing position
            let existing = try context.fetch(
                FetchDescriptor<StockItem>(
                    predicate: #Predicate<StockItem> { $0.code == symbol }
                )
            ).first

            if let pos = existing {
                // Update cost basis + avg cost
                let newCostBasis = pos.costBasis + totalCost
                let newShares = pos.sharesOwned + shares
                pos.sharesOwned = newShares
                pos.costBasis = newCostBasis
                pos.avgCost = newShares > 0 ? (newCostBasis / newShares) : 0

                // Update last price snapshot too (nice to keep UI consistent immediately)
                pos.current = executionPrice
            } else {
                // Create new position (fetch quote/name if you want; here we use what we have)
                // Ideally: pass name & quote in, or fetch here.
                let quote = try await SwiftStockAPI.shared.fetchQuote(for: symbol)
                let name = try await SwiftStockAPI.shared.fetchCompanyName(for: symbol)

                let newPos = StockItem(
                    name: name,
                    code: symbol,
                    current: quote.current,
                    change: quote.change,
                    percentChange: quote.percentChange,
                    high: quote.high,
                    low: quote.low,
                    open: quote.open,
                    previousClose: quote.previousClose,
                    sharesOwned: shares,
                    avgCost: executionPrice,
                    costBasis: totalCost
                )
                context.insert(newPos)
            }

            // Deduct balance after successful update
            balance -= totalCost
            try context.save()
            return true
        } catch {
            print("Buy failed:", error)
            return false
        }
    }
    func sellStock(symbol: String, in context: ModelContext, shares: Double, executionPrice: Double) -> Bool {
        guard shares >= 0.01 else { return false }
        guard executionPrice > 0 else { return false }

        do {
            let existing = try context.fetch(
                FetchDescriptor<StockItem>(
                    predicate: #Predicate<StockItem> { $0.code == symbol }
                )
            ).first

            guard let pos = existing else {
                // You don't own it (no position)
                return false
            }

            // Check you have enough shares
            guard pos.sharesOwned >= shares else {
                return false
            }

            // Add proceeds to available money (includes profit if any)
            let proceeds = shares * executionPrice
            balance += proceeds

            // Reduce position cost basis proportionally by avg cost
            let costRemoved = shares * pos.avgCost
            pos.costBasis = max(0, pos.costBasis - costRemoved)
            pos.sharesOwned = max(0, pos.sharesOwned - shares)

            if pos.sharesOwned > 0 {
                pos.avgCost = pos.costBasis / pos.sharesOwned
            } else {
                pos.avgCost = 0
                pos.costBasis = 0

                // Optional: remove position completely when empty
                context.delete(pos)
            }

            // Optional: keep last trade price visible immediately
            pos.current = executionPrice

            try context.save()
            return true
        } catch {
            print("Sell failed:", error)
            return false
        }
    }


}
