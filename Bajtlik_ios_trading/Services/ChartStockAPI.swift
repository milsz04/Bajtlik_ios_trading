import Foundation

struct ChartStockTimeSeriesResponse: Codable {
    struct Value: Codable {
        let datetime: String
        let open: String
        let high: String
        let low: String
        let close: String
        let volume: String
    }
    
    let values: [Value]?
    let status: String?
    let message: String?
}

@MainActor
final class ChartStockAPI {
    static let shared = ChartStockAPI()
    
    private let apiKey = "314d241bc355491e9c0aeda922f9ad26"
    private let baseURL = "https://api.twelvedata.com"
    
    private init() {}
    
    private func parseDate(_ string: String) -> Date? {
        let dfDateTime = DateFormatter()
        dfDateTime.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dfDateTime.timeZone = TimeZone(identifier: "Europe/Warsaw")
        if let d = dfDateTime.date(from: string) { return d }
        
        let dfDateOnly = DateFormatter()
        dfDateOnly.dateFormat = "yyyy-MM-dd"
        dfDateOnly.timeZone = TimeZone(identifier: "Europe/Warsaw")
        if let d = dfDateOnly.date(from: string) { return d }
        
        return nil
    }
    
    func fetchTimeSeries(
        symbol: String,
        interval: String,
        outputSize: Int = 200,
        timezone: String = "Europe/Warsaw"
    ) async throws -> [PricePoint] {
        
        var components = URLComponents(string: "\(baseURL)/time_series")
        components?.queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "interval", value: interval),
            URLQueryItem(name: "outputsize", value: String(outputSize)),
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "timezone", value: timezone),
            URLQueryItem(name: "order", value: "asc"),
        ]
        
        guard let url = components?.url else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(ChartStockTimeSeriesResponse.self, from: data)
        
        if let status = decoded.status, status != "ok" {
            let message = decoded.message ?? "Unknown error"
            throw NSError(domain: "ChartStockAPI", code: -1, userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        
        guard let values = decoded.values else { return [] }
        
        let points: [PricePoint] = values.compactMap { v in
            guard let date = parseDate(v.datetime),
                  let close = Double(v.close) else { return nil }
            return PricePoint(time: date, price: close)
        }
        
        return points
    }
}
