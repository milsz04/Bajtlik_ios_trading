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
    var reservedShares: Double
    var marketValue: Double { sharesOwned * current }
    var unrealizedPL: Double { marketValue - costBasis }
    var unrealizedPLPercent: Double {
        guard costBasis > 0 else { return 0 }
        return (unrealizedPL / costBasis) * 100
    }

    var availableSharesToSell: Double {
        max(0, sharesOwned - reservedShares)
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
        costBasis: Double = 0.0,
        reservedShares: Double = 0.0
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
        self.reservedShares = reservedShares
    }
}


@MainActor
final class StockManager: ObservableObject {
    @Published var selectedStock: StockItem? = nil

    private enum PersistKeys {
        static let balance = "bajtlik.balance"
        static let reservedCash = "bajtlik.reservedCash"
    }
    private static func sanitizeMoney(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return max(0, value)
    }

    @Published var balance: Double {
        didSet {
            let clean = Self.sanitizeMoney(balance)
            if balance != clean { balance = clean; return }
            UserDefaults.standard.set(balance, forKey: PersistKeys.balance)
        }
    }

    @Published var reservedCash: Double {
        didSet {
            let clean = Self.sanitizeMoney(reservedCash)
            if reservedCash != clean { reservedCash = clean; return }
            UserDefaults.standard.set(reservedCash, forKey: PersistKeys.reservedCash)
        }
    }




    var availableCash: Double {
        let b = Self.sanitizeMoney(balance)
        let r = Self.sanitizeMoney(reservedCash)
        return max(0, b - r)
    }


    @Published var selectedStockCode: String? = nil
    @Published var selectedStockPrice: Double? = nil
    @Published var selectedSymbol: String? = nil
    @Published var selectedName: String? = nil

    init() {
        let defaults = UserDefaults.standard

        let savedBalance = defaults.object(forKey: PersistKeys.balance) as? Double
        let savedReserved = defaults.object(forKey: PersistKeys.reservedCash) as? Double

        self.balance = Self.sanitizeMoney(savedBalance ?? 10_000.00)
        self.reservedCash = Self.sanitizeMoney(savedReserved ?? 0.0)
    }


    

    func addWatchlistStock(query: String, in context: ModelContext) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let results = try await SwiftStockAPI.shared.searchStocks(matching: trimmed)
            let bestMatch = results.first(where: { ($0.type ?? "") == "Common Stock" }) ?? results.first
            guard let match = bestMatch else { return }

            let symbol = match.symbol ?? match.displaySymbol ?? trimmed.uppercased()

            let existing = try context.fetch(
                FetchDescriptor<WatchlistItem>(
                    predicate: #Predicate<WatchlistItem> { item in item.code == symbol }
                )
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
    func refreshWatchlistStocks(stocks: [WatchlistItem], in context: ModelContext) async {
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
                print("Failed to refresh watchlist \(stock.code):", error)
            }
        }

        do { try context.save() }
        catch { print("Failed to save refreshed watchlist:", error) }
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
        selectedStockCode = stock.code
        selectedStockPrice = stock.current
    }

    func select(watchlist: WatchlistItem) {
        selectedStock = nil
        selectedSymbol = watchlist.code
        selectedName = watchlist.name
        selectedStockCode = watchlist.code
        selectedStockPrice = watchlist.current
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
        await processLimitOrders(in: context)
    }


    func tryBuy(shares: Double, pricePerShare: Double) -> Bool {
        guard shares >= 0.01, pricePerShare > 0 else { return false }
        let totalCost = shares * pricePerShare
        guard totalCost <= balance else { return false }
        balance -= totalCost
        return true
    }



    func buyStock(symbol: String, in context: ModelContext, shares: Double, executionPrice: Double) async -> Bool {
        guard shares >= 0.01, executionPrice > 0 else { return false }

        let totalCost = shares * executionPrice
        guard totalCost <= balance else { return false }


        do {
            let existing = try context.fetch(
                FetchDescriptor<StockItem>(
                    predicate: #Predicate<StockItem> { item in item.code == symbol }
                )
            ).first

            if let pos = existing {
                let newCostBasis = pos.costBasis + totalCost
                let newShares = pos.sharesOwned + shares
                pos.sharesOwned = newShares
                pos.costBasis = newCostBasis
                pos.avgCost = newShares > 0 ? (newCostBasis / newShares) : 0
                pos.current = executionPrice
            } else {
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
                    costBasis: totalCost,
                    reservedShares: 0
                )
                context.insert(newPos)
            }

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
                    predicate: #Predicate<StockItem> { item in item.code == symbol }
                )
            ).first

            guard let pos = existing else { return false }
            guard pos.sharesOwned >= shares else { return false }

            let proceeds = shares * executionPrice
            balance += proceeds

            let costRemoved = shares * pos.avgCost
            pos.costBasis = max(0, pos.costBasis - costRemoved)
            pos.sharesOwned = max(0, pos.sharesOwned - shares)

            if pos.sharesOwned > 0 {
                pos.avgCost = pos.costBasis / pos.sharesOwned
            } else {
                pos.avgCost = 0
                pos.costBasis = 0
                pos.reservedShares = 0
                context.delete(pos)
            }

            pos.current = executionPrice
            try context.save()
            return true
        } catch {
            print("Sell failed:", error)
            return false
        }
    }


    func placeLimitOrder(
        symbol: String,
        name: String,
        side: String,
        shares: Double,
        limitPrice: Double,
        in context: ModelContext
    ) -> Bool {
        guard shares >= 0.01, limitPrice > 0 else { return false }

        guard side == "Buy" || side == "Sell" else { return false }

        if side == "Buy" {
            let required = shares * limitPrice
            guard availableCash >= required else { return false }

            reservedCash += required

            let order = LimitOrder(
                symbol: symbol,
                name: name,
                side: "Buy",
                shares: shares,
                limitPrice: limitPrice
            )
            context.insert(order)
            do { try context.save(); return true }
            catch {
                reservedCash = max(0, reservedCash - required)
                return false
            }
        } else {
            do {
                let pos = try context.fetch(
                    FetchDescriptor<StockItem>(
                        predicate: #Predicate<StockItem> { item in
                            item.code == symbol
                        }
                    )
                ).first
                
                guard let pos else { return false }
                guard pos.availableSharesToSell >= shares else { return false }
                
                pos.reservedShares += shares
                
                let order = LimitOrder(
                    symbol: symbol,
                    name: name,
                    side: "Sell",
                    shares: shares,
                    limitPrice: limitPrice
                )
                context.insert(order)
                
                do {
                    try context.save()
                    return true
                } catch {
                    pos.reservedShares = max(0, pos.reservedShares - shares)
                    return false
                }
            } catch {
                return false
            }
        }
    }
    func cancelLimitOrder(_ order: LimitOrder, in context: ModelContext) {
        if order.side == "Buy" {
            let reserved = order.shares * order.limitPrice
            reservedCash = max(0, reservedCash - reserved)
            context.delete(order)
            do { try context.save() } catch {}
            return
        }
        do {
            let symbol = order.symbol

            if let pos = try context.fetch(
                FetchDescriptor<StockItem>(
                    predicate: #Predicate<StockItem> { item in
                        item.code == symbol
                    }
                )
            ).first {
                pos.reservedShares = max(0, pos.reservedShares - order.shares)
            }

            context.delete(order)
            try context.save()
        } catch {}
    }

    func processLimitOrders(in context: ModelContext) async {
        do {
            let orders = try context.fetch(
                FetchDescriptor<LimitOrder>(sortBy: [SortDescriptor(\LimitOrder.createdAt)])
            )

            for order in orders {
                let symbol = order.symbol

                let quote = try await SwiftStockAPI.shared.fetchQuote(for: symbol)
                let current = quote.current

                if order.side == "Buy" {
                    guard current <= order.limitPrice else { continue }

                    let reserved = order.shares * order.limitPrice
                    reservedCash = max(0, reservedCash - reserved)

                    let ok = await buyStock(
                        symbol: symbol,
                        in: context,
                        shares: order.shares,
                        executionPrice: current
                    )

                    if ok {
                        context.delete(order)
                    } else {
                        reservedCash += reserved
                    }

                } else { 
                    guard current >= order.limitPrice else { continue }

                    if let pos = try context.fetch(
                        FetchDescriptor<StockItem>(
                            predicate: #Predicate<StockItem> { item in
                                item.code == symbol
                            }
                        )
                    ).first {
                        pos.reservedShares = max(0, pos.reservedShares - order.shares)
                    }

                    let ok = sellStock(
                        symbol: symbol,
                        in: context,
                        shares: order.shares,
                        executionPrice: current
                    )

                    if ok {
                        context.delete(order)
                    } else {
                        if let pos = try context.fetch(
                            FetchDescriptor<StockItem>(
                                predicate: #Predicate<StockItem> { item in
                                    item.code == symbol
                                }
                            )
                        ).first {
                            pos.reservedShares += order.shares
                        }
                    }
                }
            }

            try context.save()
        } catch {
            print("processLimitOrders error:", error)
        }
    }
    @MainActor
    func resetAccount() {
        balance = 10000.00
        reservedCash = 0.0
    }


}

