import SwiftUI

struct DetailedStockView: View {
    @EnvironmentObject var stockManager: StockManager
    
    @State private var selectedTimeRange: TimeRange = .oneDay
    @State private var chartData: [PricePoint] = []
    @State private var isLoadingChart = false
    @State private var chartError: String?
    
    enum TimeRange: String, CaseIterable {
        case oneDay      = "1D"
        case sevenDays   = "7D"
        case oneMonth    = "1M"
        case sixMonths   = "6M"
        case oneYear     = "1Y"
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            
            if let stock = stockManager.selectedStock {
                VStack(alignment: .leading, spacing: 16) {
                    
                    HStack {
                        Text(stock.code)
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
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name: \(stock.name)")
                            .font(.system(size: 20, design: .monospaced))
                        
                        Text("Code: \(stock.code)")
                            .font(.system(size: 20, design: .monospaced))
                        
                        Text("Price: $\(String(format: "%.2f", stock.current))")
                            .font(.system(size: 20, design: .monospaced))
                        
                        Text("Change: \(stock.change > 0 ? "+" : "")\(String(stock.change)) (\(String(format: "%.3f", stock.percentChange))%)")
                            .font(.system(size: 20, weight: .regular, design: .monospaced))
                            .foregroundColor(stock.change > 0 ? .green : .red)
                    }
                    
                    //Spacer()
                    
                    VStack(spacing: 12) {
                        if isLoadingChart {
                            ProgressView("Loading chart...")
                                .padding()
                        } else if let chartError = chartError {
                            Text(chartError)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        } else if chartData.isEmpty {
                            Text("No chart data available.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        } else {
                            StockLineChart(
                                data: chartData,
                                isPositive: stock.change >= 0,
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
//                    .padding(.horizontal)
//                    .padding(.top, 4)
                    
                    Divider()
                        .padding(.top, 8)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Open")
                                .font(.system(size: 24, design: .monospaced))
                            Spacer()
                            Text("$\(String(format: "%.2f", stock.open))")
                                .font(.system(size: 24, design: .monospaced))
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("High")
                                .font(.system(size: 24, design: .monospaced))
                            Spacer()
                            Text("$\(String(format: "%.2f", stock.high))")
                                .font(.system(size: 24, design: .monospaced))
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Low")
                                .font(.system(size: 24, design: .monospaced))
                            Spacer()
                            Text("$\(String(format: "%.2f", stock.low))")
                                .font(.system(size: 24, design: .monospaced))
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .onAppear {
                    loadChartData(for: stock)
                }
                .onChange(of: selectedTimeRange) { _, _ in
                    if let s = stockManager.selectedStock {
                        loadChartData(for: s)
                    }
                }
                
            } else {
                Text("No stock selected")
                    .font(.system(size: 24, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func loadChartData(for stock: StockItem) {
        let interval = selectedTimeRange.interval
        let size = selectedTimeRange.outputSize
        
        Task {
            await MainActor.run {
                isLoadingChart = true
                chartError = nil
            }
            
            do {
                let points = try await ChartStockAPI.shared.fetchTimeSeries(
                    symbol: stock.code,
                    interval: interval,
                    outputSize: size
                )
                
                await MainActor.run {
                    chartData = points
                    isLoadingChart = false
                }
            } catch {
                await MainActor.run {
                    chartError = error.localizedDescription
                    chartData = []
                    isLoadingChart = false
                }
            }
        }
    }
}

extension DetailedStockView.TimeRange {
    
    var interval: String {
        switch self {
        case .oneDay:
            return "5min"
        case .sevenDays:
            return "30min"
        case .oneMonth:
            return "2h"
        case .sixMonths:
            return "1day"
        case .oneYear:
            return "1week"
        }
    }
    
    var outputSize: Int {
        switch self {
        case .oneDay:
            return 288
        case .sevenDays:
            return 336
        case .oneMonth:
            return 384
        case .sixMonths:
            return 186
        case .oneYear:
            return 52
        }
    }
    
    var chartRange: ChartTimeRange {
        switch self {
        case .oneDay:
            return .oneDay
        case .sevenDays:
            return .sevenDays
        case .oneMonth:
            return .oneMonth
        case .sixMonths:
            return .sixMonths
        case .oneYear:
            return .oneYear
        }
    }
}

#Preview {
    NavigationStack {
        DetailedStockView()
            .environmentObject(StockManager())
    }
}
