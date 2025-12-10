import Foundation
import SwiftUI

// --- Data Models ---

struct StockSearchResult: Identifiable, Codable {
    var id: String { symbol ?? UUID().uuidString }
    var symbol: String?
    var description: String?
    var displaySymbol: String?
    var type: String?
}

struct StockQuote: Codable {
    let current: Double
    let change: Double
    let percentChange: Double
    let high: Double
    let low: Double
    let open: Double
    let previousClose: Double

    enum CodingKeys: String, CodingKey {
        case current = "c"
        case change = "d"
        case percentChange = "dp"
        case high = "h"
        case low = "l"
        case open = "o"
        case previousClose = "pc"
    }
}

struct CompanyProfile: Codable {
    let name: String?
    let ticker: String?
    let marketCapitalization: Double?
    let shareOutstanding: Double?
    let logo: String?
    let weburl: String?
}

@MainActor
final class SwiftStockAPI {
    static let shared = SwiftStockAPI()
    private let apiKey = "d486td1r01qk80bjn1dgd486td1r01qk80bjn1e0"

    private let baseURL = "https://finnhub.io/api/v1"

    func searchStocks(matching term: String) async throws -> [StockSearchResult] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?q=\(encoded)&token=\(apiKey)") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.result
    }

    func fetchQuote(for symbol: String) async throws -> StockQuote {

        guard let url = URL(string: "\(baseURL)/quote?symbol=\(symbol)&token=\(apiKey)") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(StockQuote.self, from: data)
    }

    func fetchCompanyName(for symbol: String) async throws -> String {
        let urlString = "\(baseURL)/stock/profile2?symbol=\(symbol)&token=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        let profile = try JSONDecoder().decode(CompanyProfile.self, from: data)

        return profile.name ?? symbol
    }
}

private struct SearchResponse: Codable {
    let count: Int
    let result: [StockSearchResult]
}
