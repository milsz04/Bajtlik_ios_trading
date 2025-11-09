import SwiftUI
import Combine

@MainActor
final class StockFetcher: ObservableObject {
    @Published var stockQuote: StockQuote?
    @Published var searchResults: [StockSearchResult] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    func fetchStockQuote(for symbol: String) {
        Task {
            do {
                isLoading = true
                let quote = try await SwiftStockAPI.shared.fetchQuote(for: symbol)
                stockQuote = quote
                errorMessage = nil
            } catch {
                errorMessage = "Error fetching quote: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    func searchStocks(matching term: String) {
        Task {
            guard !term.isEmpty else {
                searchResults = []
                return
            }
            do {
                isLoading = true
                let results = try await SwiftStockAPI.shared.searchStocks(matching: term)
                searchResults = results
                errorMessage = nil
            } catch {
                errorMessage = "Error searching stocks: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}

