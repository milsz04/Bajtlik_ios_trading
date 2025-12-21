import Foundation
import SwiftData
import Combine

@MainActor
final class BajtlikViewModel: ObservableObject {

    struct PortfolioSummary {
        let totalValue: Double
        let totalUnrealizedPL: Double
        var isProfit: Bool { totalUnrealizedPL >= 0 }
    }


    func summary(balance: Double, stocks: [StockItem]) -> PortfolioSummary {
        let totalValue = balance + stocks.reduce(0) { $0 + $1.marketValue }
        let totalUnrealizedPL = stocks.reduce(0) { $0 + $1.unrealizedPL }
        return PortfolioSummary(totalValue: totalValue, totalUnrealizedPL: totalUnrealizedPL)
    }

    func openDetails(for item: StockItem, stockManager: StockManager, context: ModelContext) {
        stockManager.select(stock: item)
        Task { await stockManager.processLimitOrders(in: context) }
    }

    func refreshPortfolio(stocks: [StockItem], stockManager: StockManager, context: ModelContext) async {
        await stockManager.refreshAllStocks(stocks: stocks, in: context)
    }
}

