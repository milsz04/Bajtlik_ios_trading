import SwiftUI
import SwiftData
import Combine
import AudioToolbox

@MainActor
final class TradeViewModel: ObservableObject {

    @Published var tradeType = "Sell"
    @Published var orderType = "Market"
    @Published var shares: Double = 1.00
    @Published var stockPrice: Double = 150.2
    @Published var stockCode: String = "firmaA"
    @Published var selectedSymbolInPicker: String = ""
    @Published var showInsufficientFundsAlert = false
    @Published var showSuccessAlert = false
    @Published var showInsufficientSharesAlert = false
    @Published var showLimitAlert = false
    @Published var limitText = ""
    @Published var showLimitFailedAlert = false
    @Published var logoURL: URL? = nil
    @Published var showSellPLAlert = false
    @Published var lastSellPL: Double = 0
    @Published var lastSellSymbol: String = ""


    var estimatedCost: Double { shares * stockPrice }
    var isSharesValid: Bool { shares >= 0.01 }


    static let sharesFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.minimum = 0.01
        return formatter
    }()

    func activeSymbol(stockManager: StockManager) -> String {
        stockManager.selectedStock?.code
        ?? (selectedSymbolInPicker.isEmpty ? nil : selectedSymbolInPicker)
        ?? stockManager.selectedSymbol
        ?? stockManager.selectedStockCode
        ?? stockCode
    }

    func onAppear(
        stockManager: StockManager,
        watchlistStocks: [WatchlistItem]
    ) {
        if let stock = stockManager.selectedStock {
            stockCode = stock.code
            stockPrice = stock.current
            selectedSymbolInPicker = stock.code
            loadLogo(for: selectedSymbolInPicker.isEmpty ? activeSymbol(stockManager: stockManager) : selectedSymbolInPicker)
            return
        }

        if let sym = stockManager.selectedSymbol ?? stockManager.selectedStockCode, !sym.isEmpty {
            stockCode = sym
            selectedSymbolInPicker = sym
            if let price = stockManager.selectedStockPrice {
                stockPrice = price
            }
        } else if let first = watchlistStocks.first {
            stockCode = first.code
            stockPrice = first.current
            selectedSymbolInPicker = first.code
            stockManager.select(watchlist: first)
        }

        loadLogo(for: selectedSymbolInPicker.isEmpty ? activeSymbol(stockManager: stockManager) : selectedSymbolInPicker)
    }

    func onSymbolChanged(
        _ newSymbol: String,
        stockManager: StockManager,
        watchlistStocks: [WatchlistItem]
    ) {
        guard !newSymbol.isEmpty else { return }

        stockCode = newSymbol

        if let w = watchlistStocks.first(where: { $0.code == newSymbol }) {
            stockPrice = w.current
            stockManager.select(watchlist: w)
        } else {
            stockManager.selectedSymbol = newSymbol
            stockManager.selectedStockCode = newSymbol
            stockManager.selectedStockPrice = stockPrice
        }

        loadLogo(for: newSymbol)
    }

    func placeOrder(
        stockManager: StockManager,
        context: ModelContext
    ) {
        let symbol = activeSymbol(stockManager: stockManager)

        if orderType == "Limit" {
            limitText = String(format: "%.2f", stockPrice)
            showLimitAlert = true
            return
        }

        if tradeType == "Buy" {
            Task {
                let success = await stockManager.buyStock(
                    symbol: symbol,
                    in: context,
                    shares: shares,
                    executionPrice: stockPrice
                )
                if success {
                    showSuccessAlert = true
                } else {
                    showInsufficientFundsAlert = true
                }
            }
        } else {
            
            let avgCost = avgCostForSymbol(symbol, context: context) ?? 0
            let realizedPL = (stockPrice - avgCost) * shares

            let success = stockManager.sellStock(
                symbol: symbol,
                in: context,
                shares: shares,
                executionPrice: stockPrice
            )

            if success {
                lastSellPL = realizedPL
                lastSellSymbol = symbol
                showSellPLAlert = true

                AudioServicesPlaySystemSound(realizedPL > 0 ? 1022 : 1006)
            } else {
                showInsufficientSharesAlert = true
            }
        }
    }

    func placeLimitOrderConfirmed(
        stockManager: StockManager,
        context: ModelContext
    ) {
        let symbol = activeSymbol(stockManager: stockManager)

        let name = stockManager.selectedStock?.name
        ?? stockManager.selectedName
        ?? symbol

        let limitPrice = Double(limitText.replacingOccurrences(of: ",", with: ".")) ?? 0

        let ok = stockManager.placeLimitOrder(
            symbol: symbol,
            name: name,
            side: tradeType,
            shares: shares,
            limitPrice: limitPrice,
            in: context
        )

        if ok {
            showSuccessAlert = true
        } else {
            showLimitFailedAlert = true
        }
    }


    func loadLogo(for symbol: String) {
        Task {
            do {
                let url = try await SwiftStockAPI.shared.fetchCompanyLogoURL(for: symbol)
                self.logoURL = url
            } catch {
                self.logoURL = nil
            }
        }
    }

    private func avgCostForSymbol(_ symbol: String, context: ModelContext) -> Double? {
        do {
            let pos = try context.fetch(
                FetchDescriptor<StockItem>(
                    predicate: #Predicate<StockItem> { item in item.code == symbol }
                )
            ).first
            return pos?.avgCost
        } catch {
            return nil
        }
    }
}

