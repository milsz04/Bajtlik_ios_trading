import SwiftUI
import SwiftData
import Combine

final class WatchlistViewModel: ObservableObject {
    @Published var showSearchField = false
    @Published var stockSymbol = ""

    @Published var showSearchBar = false
    @Published var searchText = ""
    
    func filteredStocks(from stocks: [WatchlistItem]) -> [WatchlistItem] {
        guard !searchText.isEmpty else { return stocks }

        return stocks.filter { item in
            item.name.lowercased().contains(searchText.lowercased()) ||
            item.code.lowercased().contains(searchText.lowercased())
        }
    }

}


