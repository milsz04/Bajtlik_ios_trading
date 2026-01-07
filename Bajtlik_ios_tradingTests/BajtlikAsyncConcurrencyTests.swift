import XCTest
import Combine

@testable import Bajtlik_ios_trading


final class URLProtocolStub: URLProtocol {
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

    static var handler: Handler?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = URLProtocolStub.handler else {
            XCTFail("URLProtocolStub.handler not set")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { }
}


@MainActor
final class BajtlikAsyncConcurrencyTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(URLProtocolStub.self)

        URLProtocolStub.handler = nil
    }

    override func tearDown() {
        URLProtocolStub.handler = nil
        URLProtocol.unregisterClass(URLProtocolStub.self)
        super.tearDown()
    }

    // MARK: - StockFetcher async behavior (success)

    func testStockFetcher_fetchStockQuote_success_setsQuoteAndClearsError() async {
        // Arrange
        let expectedJSON = """
        { "c": 123.45, "d": 1.2, "dp": 0.98, "h": 130.0, "l": 120.0, "o": 122.0, "pc": 122.25 }
        """.data(using: .utf8)!

        URLProtocolStub.handler = { request in
            guard let url = request.url else { throw URLError(.badURL) }
            // This call comes from SwiftStockAPI.fetchQuote(for:) :contentReference[oaicite:3]{index=3}
            if url.host == "finnhub.io", url.path.contains("/quote") {
                let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (resp, expectedJSON)
            }
            throw URLError(.unsupportedURL)
        }

        let fetcher = StockFetcher()
        let done = expectation(description: "quote loaded")

        let cancellable = fetcher.$stockQuote.sink { quote in
            if quote != nil { done.fulfill() }
        }
        defer { cancellable.cancel() }

        fetcher.fetchStockQuote(for: "AAPL")

        await fulfillment(of: [done], timeout: 2.0)
        XCTAssertFalse(fetcher.isLoading)
        XCTAssertNil(fetcher.errorMessage)
        XCTAssertNotNil(fetcher.stockQuote)

        guard let quote = fetcher.stockQuote else {
            XCTFail("Expected stockQuote to be set")
            return
        }

        XCTAssertEqual(quote.current, 123.45, accuracy: 0.0001)
        XCTAssertEqual(quote.open, 122.0, accuracy: 0.0001)
    }

    // MARK: - StockFetcher async behavior (failure)

    func testStockFetcher_fetchStockQuote_failure_setsErrorAndStopsLoading() async {
        URLProtocolStub.handler = { request in
            guard let url = request.url else { throw URLError(.badURL) }
            if url.host == "finnhub.io", url.path.contains("/quote") {
                // Simulate network failure
                throw URLError(.timedOut)
            }
            throw URLError(.unsupportedURL)
        }

        let fetcher = StockFetcher()
        let done = expectation(description: "error set")

        let cancellable = fetcher.$errorMessage.sink { msg in
            if msg != nil { done.fulfill() }
        }
        defer { cancellable.cancel() }

        fetcher.fetchStockQuote(for: "AAPL")

        await fulfillment(of: [done], timeout: 2.0)
        XCTAssertFalse(fetcher.isLoading)
        XCTAssertNotNil(fetcher.errorMessage)
        XCTAssertNil(fetcher.stockQuote)
    }

    // MARK: - SwiftStockAPI concurrency: many concurrent fetchQuote calls

    func testSwiftStockAPI_concurrentFetchQuote_allReturn() async throws {
        URLProtocolStub.handler = { request in
            guard let url = request.url else { throw URLError(.badURL) }

            if url.host == "finnhub.io", url.path.contains("/quote") {
                let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let symbol = comps?.queryItems?.first(where: { $0.name == "symbol" })?.value ?? "X"

                let price: Double
                switch symbol {
                case "AAA": price = 10
                case "BBB": price = 20
                case "CCC": price = 30
                default:    price = 99
                }

                let json = """
                { "c": \(price), "d": 0, "dp": 0, "h": 0, "l": 0, "o": 0, "pc": 0 }
                """.data(using: .utf8)!

                let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (resp, json)
            }
            throw URLError(.unsupportedURL)
        }

        async let q1 = SwiftStockAPI.shared.fetchQuote(for: "AAA")
        async let q2 = SwiftStockAPI.shared.fetchQuote(for: "BBB")
        async let q3 = SwiftStockAPI.shared.fetchQuote(for: "CCC")

        let (a, b, c) = try await (q1, q2, q3)

        XCTAssertEqual(a.current, 10, accuracy: 0.0001)
        XCTAssertEqual(b.current, 20, accuracy: 0.0001)
        XCTAssertEqual(c.current, 30, accuracy: 0.0001)
    }

    // MARK: - ChartStockAPI async: parsing + ordering

    func testChartStockAPI_fetchTimeSeries_parsesAndReturnsPoints() async throws {
        let json = """
        {
          "values": [
            { "datetime": "2026-01-01 10:00:00", "open": "1", "high": "1", "low": "1", "close": "100.0", "volume": "1" },
            { "datetime": "2026-01-01 10:05:00", "open": "1", "high": "1", "low": "1", "close": "101.0", "volume": "1" }
          ],
          "status": "ok"
        }
        """.data(using: .utf8)!

        URLProtocolStub.handler = { request in
            guard let url = request.url else { throw URLError(.badURL) }
            if url.host == "api.twelvedata.com", url.path.contains("/time_series") {
                let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (resp, json)
            }
            throw URLError(.unsupportedURL)
        }

        let points = try await ChartStockAPI.shared.fetchTimeSeries(
            symbol: "AAPL",
            interval: "5min",
            outputSize: 2
        )

        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points[0].price, 100.0, accuracy: 0.0001)
        XCTAssertEqual(points[1].price, 101.0, accuracy: 0.0001)
        XCTAssertLessThan(points[0].time, points[1].time)
    }


    func testChartStockAPI_fetchTimeSeries_statusErrorThrows() async {
        let json = """
        { "status": "error", "message": "Invalid API key" }
        """.data(using: .utf8)!

        URLProtocolStub.handler = { request in
            guard let url = request.url else { throw URLError(.badURL) }
            if url.host == "api.twelvedata.com", url.path.contains("/time_series") {
                let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (resp, json)
            }
            throw URLError(.unsupportedURL)
        }

        do {
            _ = try await ChartStockAPI.shared.fetchTimeSeries(symbol: "AAPL", interval: "5min", outputSize: 2)
            XCTFail("Expected fetchTimeSeries to throw when status != ok")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Invalid API key"))
        }
    }
}

