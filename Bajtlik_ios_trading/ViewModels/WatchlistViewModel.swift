import Foundation
import SwiftData
import Combine
import SwiftUI
@MainActor
final class WatchlistViewModel: ObservableObject {

    @Published var showSearchField = false
    @Published var stockSymbol = ""

    @Published var showSearchBar = false
    @Published var searchText = ""

    @Published var selectedStockForDetails: WatchlistItem?

    func toggleSearchBar() {
        withAnimation(.easeInOut) {
            showSearchBar.toggle()
            if !showSearchBar {
                searchText = ""
            }
        }
    }

    func openDetails(for item: WatchlistItem, stockManager: StockManager) {
        selectedStockForDetails = item
        stockManager.select(watchlist: item)
    }

    func addSymbol(stockManager: StockManager, context: ModelContext) {
        let symbol = stockSymbol
        Task {
            await stockManager.addWatchlistStock(query: symbol, in: context)
            stockSymbol = ""
        }
    }

    func cancelAdd() {
        stockSymbol = ""
    }

    func remove(_ item: WatchlistItem, stockManager: StockManager, context: ModelContext) {
        stockManager.removeWatchlistStock(item, in: context)
    }

    func refreshWatchlist(stocks: [WatchlistItem], stockManager: StockManager, context: ModelContext) {
        Task {
            await stockManager.refreshWatchlistStocks(stocks: stocks, in: context)
        }
    }


    func filteredStocks(from stocks: [WatchlistItem]) -> [WatchlistItem] {
        guard !searchText.isEmpty else { return stocks }

        let q = searchText.lowercased()
        return stocks.filter { item in
            item.name.lowercased().contains(q) || item.code.lowercased().contains(q)
        }
    }
}

