import SwiftUI

struct DetailedStockView: View {
    @EnvironmentObject var stockManager: StockManager
    @State private var selectedTimeRange: TimeRange = .oneDay
    @StateObject private var viewModel = DetailedStockViewModel()

    // MARK: - Time Range
    enum TimeRange: String, CaseIterable {
        case oneDay      = "1D"
        case sevenDays   = "7D"
        case oneMonth    = "1M"
        case sixMonths   = "6M"
        case oneYear     = "1Y"
    }

    // MARK: - Watchlist fallback quote snapshot
    @State private var fallbackQuote: QuoteSnapshot?
    @State private var isLoadingQuote = false

    private struct QuoteSnapshot {
        let current: Double
        let change: Double
        let percentChange: Double
        let open: Double
        let high: Double
        let low: Double
    }

    private var symbol: String {
        stockManager.selectedStock?.code
        ?? stockManager.selectedSymbol
        ?? stockManager.selectedStockCode
        ?? ""
    }

    private var name: String {
        stockManager.selectedStock?.name
        ?? stockManager.selectedName
        ?? symbol
    }

    private var currentPrice: Double? {
        stockManager.selectedStock?.current
        ?? fallbackQuote?.current
        ?? stockManager.selectedStockPrice
    }

    private var displayChange: Double? {
        stockManager.selectedStock?.change ?? fallbackQuote?.change
    }

    private var displayPercentChange: Double? {
        stockManager.selectedStock?.percentChange ?? fallbackQuote?.percentChange
    }

    private var displayOpen: Double? {
        stockManager.selectedStock?.open ?? fallbackQuote?.open
    }

    private var displayHigh: Double? {
        stockManager.selectedStock?.high ?? fallbackQuote?.high
    }

    private var displayLow: Double? {
        stockManager.selectedStock?.low ?? fallbackQuote?.low
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            if symbol.isEmpty {
                Text("No stock selected")
                    .font(.system(size: 24, design: .monospaced))
                    .foregroundColor(.gray)
            } else {
                VStack(alignment: .leading, spacing: 16) {

                    HStack {
                        Text(symbol)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)

                        Spacer()

                        NavigationLink(
                            destination: TradeView()
                                .environmentObject(stockManager)
                        ) {
                            Text("Trade")
                                .font(.system(size: 24, weight: .regular, design: .monospaced))
                                .padding(.horizontal, 50)
                                .padding(.vertical, 15)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1),
                                                radius: 10, x: 0, y: 4)
                                )
                                .foregroundColor(.black.opacity(0.8))
                        }
                        .onTapGesture {
                            // Guarantee TradeView has data
                            stockManager.selectedStockCode = symbol
                            stockManager.selectedStockPrice = currentPrice
                            stockManager.selectedSymbol = symbol
                            stockManager.selectedName = name
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name: \(name)")
                            .font(.system(size: 20, design: .monospaced))

                        Text("Code: \(symbol)")
                            .font(.system(size: 20, design: .monospaced))

                        if let price = currentPrice {
                            Text("Price: $\(String(format: "%.2f", price))")
                                .font(.system(size: 20, design: .monospaced))
                        } else {
                            Text("Price: —")
                                .font(.system(size: 20, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        if let ch = displayChange, let pct = displayPercentChange {
                            Text("Change: \(ch > 0 ? "+" : "")\(String(ch)) (\(String(format: "%.3f", pct))%)")
                                .font(.system(size: 20, weight: .regular, design: .monospaced))
                                .foregroundColor(ch > 0 ? .green : .red)
                        } else if isLoadingQuote {
                            Text("Change: loading…")
                                .font(.system(size: 20, weight: .regular, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }

                    VStack(spacing: 12) {
                        if viewModel.isLoadingChart {
                            ProgressView("Loading chart...")
                                .padding()
                        } else if let chartError = viewModel.chartError {
                            Text(chartError)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        } else if viewModel.chartData.isEmpty {
                            Text("No chart data available.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        } else {
                            StockLineChart(
                                data: viewModel.chartData,
                                isPositive: (displayChange ?? 0) >= 0,
                                range: selectedTimeRange.chartRange
                            )
                        }

                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)

                    // ✅ Show Open/High/Low for BOTH portfolio + watchlist (if we have values)
                    if let o = displayOpen, let h = displayHigh, let l = displayLow {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Open")
                                    .font(.system(size: 24, design: .monospaced))
                                Spacer()
                                Text("$\(String(format: "%.2f", o))")
                                    .font(.system(size: 24, design: .monospaced))
                            }

                            Divider()

                            HStack {
                                Text("High")
                                    .font(.system(size: 24, design: .monospaced))
                                Spacer()
                                Text("$\(String(format: "%.2f", h))")
                                    .font(.system(size: 24, design: .monospaced))
                            }

                            Divider()

                            HStack {
                                Text("Low")
                                    .font(.system(size: 24, design: .monospaced))
                                Spacer()
                                Text("$\(String(format: "%.2f", l))")
                                    .font(.system(size: 24, design: .monospaced))
                            }
                        }
                    }

                    Spacer(minLength: 8)
                }
                .padding()
                .onAppear {
                    loadFallbackQuoteIfNeeded()
                    loadChartData(symbol: symbol)
                }
                .onChange(of: selectedTimeRange) { _, _ in
                    loadChartData(symbol: symbol)
                }
            }
        }
    }

    // MARK: - Fallback quote loader (watchlist path)
    private func loadFallbackQuoteIfNeeded() {
        // If portfolio selectedStock exists, we already have full quote fields.
        guard stockManager.selectedStock == nil else { return }
        guard !symbol.isEmpty else { return }
        guard !isLoadingQuote else { return }

        isLoadingQuote = true

        Task {
            do {
                let q = try await SwiftStockAPI.shared.fetchQuote(for: symbol)
                await MainActor.run {
                    fallbackQuote = QuoteSnapshot(
                        current: q.current,
                        change: q.change,
                        percentChange: q.percentChange,
                        open: q.open,
                        high: q.high,
                        low: q.low
                    )
                    isLoadingQuote = false
                }
            } catch {
                await MainActor.run {
                    isLoadingQuote = false
                }
            }
        }
    }

    // MARK: - Chart loader
    private func loadChartData(symbol: String) {
        let interval = selectedTimeRange.interval
        let size = selectedTimeRange.outputSize

        Task {
            await MainActor.run {
                viewModel.isLoadingChart = true
                viewModel.chartError = nil
            }

            do {
                let points = try await ChartStockAPI.shared.fetchTimeSeries(
                    symbol: symbol,
                    interval: interval,
                    outputSize: size
                )

                await MainActor.run {
                    viewModel.chartData = points
                    viewModel.isLoadingChart = false
                }
            } catch {
                await MainActor.run {
                    viewModel.chartError = error.localizedDescription
                    viewModel.chartData = []
                    viewModel.isLoadingChart = false
                }
            }
        }
    }
}

extension DetailedStockView.TimeRange {
    var interval: String {
        switch self {
        case .oneDay: return "5min"
        case .sevenDays: return "30min"
        case .oneMonth: return "2h"
        case .sixMonths: return "1day"
        case .oneYear: return "1week"
        }
    }

    var outputSize: Int {
        switch self {
        case .oneDay: return 288
        case .sevenDays: return 336
        case .oneMonth: return 384
        case .sixMonths: return 186
        case .oneYear: return 52
        }
    }

    var chartRange: ChartTimeRange {
        switch self {
        case .oneDay: return .oneDay
        case .sevenDays: return .sevenDays
        case .oneMonth: return .oneMonth
        case .sixMonths: return .sixMonths
        case .oneYear: return .oneYear
        }
    }
}

