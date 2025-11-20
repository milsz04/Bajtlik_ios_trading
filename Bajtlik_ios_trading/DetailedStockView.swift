import SwiftUI

struct DetailedStockView: View {
    @EnvironmentObject var stockManager: StockManager

    private let hourlyPrices: [Int: Double] = [
        0: 34.10, 1: 33.92, 2: 34.35, 3: 33.70, 4: 33.82, 5: 34.40,
        6: 33.55, 7: 33.90, 8: 34.25, 9: 33.10, 10: 33.95, 11: 34.60,
        12: 33.68, 13: 33.40, 14: 34.05, 15: 34.90, 16: 34.20, 17: 33.60,
        18: 34.30, 19: 33.55, 20: 33.85, 21: 34.50, 22: 34.05, 23: 34.20, 24: 34.5
    ]

    private var chartData: [PricePoint] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return hourlyPrices
            .sorted { $0.key < $1.key }
            .compactMap { (h, price) in
                guard let t = cal.date(byAdding: .hour, value: h, to: start) else { return nil }
                return PricePoint(time: t, price: price)
            }
    }
    @State private var selectedTimeRange: TimeRange = .day

    enum TimeRange: String, CaseIterable{
        case day = "D"
        case week = "W"
        case month = "M"
        case sixMonths = "6M"
        case oneYear = "1Y"
    }

    

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            if let stock = stockManager.selectedStock {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(stock.code)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)

                        Spacer()

                        NavigationLink(destination: TradeView()
                            .environmentObject(stockManager)
                                
                        ) {
                            Text("Trade")
                                .font(.system(size: 24, weight: .regular, design: .monospaced))
                                .padding(.horizontal, 50)
                                .padding(.vertical, 15)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                                )
                                .foregroundColor(.black.opacity(0.8))
                        }
                    }

                    Text("Name: \(stock.name)")
                        .font(.system(size: 20, design: .monospaced))

                    Text("Code: \(stock.code)")
                        .font(.system(size: 20, design: .monospaced))

                    Text("Price: $\(String(format: "%.2f", stock.low))")
                        .font(.system(size: 20, design: .monospaced))
            
                    Text("Change: \(stock.change > 0 ? "+" : "")\(String(stock.change)) (\(String(format: "%.3f",stock.percentChange))%)")
                        .font(.system(size: 20, weight: .regular, design: .monospaced))
                        .foregroundColor(stock.change > 0 ? .green : .red)

                    

                    StockLineChart(
                        data: chartData,
                        isPositive: stock.change >= 0
                    )
                    .padding(.horizontal)
                    
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer()
                    Divider()

                    HStack {
                        Text("Open").font(.system(size: 24, design: .monospaced))
                        Spacer()
                        Text("$\(String(format: "%.2f", stock.open))").font(.system(size: 24, design: .monospaced))
                    }

                    Divider()
                    HStack {
                        Text("High").font(.system(size: 24, design: .monospaced))
                        Spacer()
                        Text("$\(String(format: "%.2f", stock.high))").font(.system(size: 24, design: .monospaced))

                    }
                    Divider()
                    HStack {
                        Text("Low").font(.system(size: 24, design: .monospaced))
                        Spacer()
                        Text("$\(String(format: "%.2f", stock.low))").font(.system(size: 24, design: .monospaced))
                    }
                    Divider()
                    HStack {
                        Text("Volume").font(.system(size: 24, design: .monospaced))
                        Spacer()
                        Text("150.23").font(.system(size: 24, design: .monospaced))
                    }
                }
                .padding()

            } else {
                Text("No stock selected")
                    .font(.system(size: 24, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DetailedStockView()
            .environmentObject(StockManager())
    }
}
