import Foundation
import SwiftUI

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

struct CandleData: Codable {
    let timestamps: [Double]
    let opens: [Double]
    let highs: [Double]
    let lows: [Double]
    let closes: [Double]
    let status: String

    enum CodingKeys: String, CodingKey {
        case timestamps = "t"
        case opens = "o"
        case highs = "h"
        case lows = "l"
        case closes = "c"
        case status = "s"
    }
}

enum ChartTimeRange: String, CaseIterable {
    case oneDay = "1D"
    case fiveDays = "5D"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case oneYear = "1Y"
}

//API Manager

@MainActor
final class SwiftStockAPI {
    static let shared = SwiftStockAPI()
    
    private let apiKey = "d486td1r01qk80bjn1dgd486td1r01qk80bjn1e0"
    
    private let baseURL = "https://finnhub.io/api/v1"

    //Stock Search

    func searchStocks(matching term: String) async throws -> [StockSearchResult] {
        guard let url = URL(string: "\(baseURL)/search?q=\(term)&token=\(apiKey)") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.result
    }

    //Fetch Stock Quote

    func fetchQuote(for symbol: String) async throws -> StockQuote {
        
        guard let url = URL(string: "\(baseURL)/quote?symbol=\(symbol)&token=\(apiKey)") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(StockQuote.self, from: data)
    }
    
    //Fetch Historical Candles

    func fetchCandles(for symbol: String, range: ChartTimeRange) async throws -> CandleData {
        let now = Int(Date().timeIntervalSince1970)
        let from: Int

        switch range {
        case .oneDay: from = now - 86400
        case .fiveDays: from = now - (5 * 86400)
        case .oneMonth: from = now - (30 * 86400)
        case .threeMonths: from = now - (90 * 86400)
        case .oneYear: from = now - (365 * 86400)
        }

        guard let url = URL(string: "\(baseURL)/stock/candle?symbol=\(symbol)&resolution=D&from=\(from)&to=\(now)&token=\(apiKey)") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(CandleData.self, from: data)
    }
}

//Private Helper Structs

private struct SearchResponse: Codable {
    let count: Int
    let result: [StockSearchResult]
}

