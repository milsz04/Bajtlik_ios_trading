import SwiftUI
import SwiftData

struct TradeView: View {
    @EnvironmentObject var stockManager: StockManager
    @Environment(\.modelContext) private var context

    @Query(sort: \WatchlistItem.code)
    private var watchlistStocks: [WatchlistItem]

    @State private var tradeType = "Sell"
    @State private var orderType = "Market"
    @State private var shares: Double = 1.00
    @State private var stockPrice: Double = 150.2
    @State private var stockCode = "firmaA"
    @State private var selectedSymbolInPicker: String = ""

    @State private var showInsufficientFundsAlert = false
    @State private var showSuccessAlert = false
    @State private var showInsufficientSharesAlert = false
    @State private var showLimitAlert = false
    @State private var limitText = ""
    @State private var showLimitFailedAlert = false
    @FocusState private var sharesFieldFocused: Bool

    var estimatedCost: Double {
        shares * stockPrice
    }

    private static let sharesFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current              // 👈 IMPORTANT
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.minimum = 0.01
        return formatter
    }()


    private var isSharesValid: Bool {
        shares >= 0.01
    }
    private var activeSymbol: String {
        stockManager.selectedStock?.code
        ?? (selectedSymbolInPicker.isEmpty ? nil : selectedSymbolInPicker)
        ?? stockManager.selectedSymbol
        ?? stockManager.selectedStockCode
        ?? stockCode
    }

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {

                HStack {
                    Text("Trade")
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)

                    Spacer()

                    if watchlistStocks.isEmpty {
                        Text(stockCode)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    } else {
                        Picker("", selection: $selectedSymbolInPicker) {
                            ForEach(watchlistStocks, id: \.code) { item in
                                Text(item.code).tag(item.code)
                            }
                        }
                        .pickerStyle(.menu)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                    }
                }
                
                Picker("Trade Type", selection: $tradeType) {
                    Text("Sell").tag("Sell")
                    Text("Buy").tag("Buy")
                }
                .pickerStyle(.segmented)
                .scaleEffect(2)
                .frame(height: 40)
                .padding(.horizontal, 100)
                Picker("Order Type", selection: $orderType) {
                    Text("Market").tag("Market")
                    Text("Limit").tag("Limit")
                }
                .pickerStyle(.segmented)
                .scaleEffect(2)
                .frame(height: 60)
                .padding(.horizontal, 100)

                Divider()
                    .padding(.vertical, 10)

                HStack {
                    Text("Price per share")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                    Spacer()
                    Text(String(format: "$%.2f", stockPrice))
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                }

                HStack {
                    Text("Shares")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                    Spacer()

                    TextField("", value: $shares, formatter: Self.sharesFormatter)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)
                        .focused($sharesFieldFocused)   // 👈 focus binding
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    sharesFieldFocused = false   // 👈 hides keyboard
                                }
                            }
                        }

                }

                HStack {
                    Text("Estimated cost")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                    Spacer()
                    Text(String(format: "$%.2f", estimatedCost))
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                }

                HStack {
                    Text("Available")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                    Spacer()
                    Text(String(format: "$%.2f", stockManager.balance))
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                }

                Spacer()

                Button(action: {
                    print("\(tradeType) \(shares) shares with \(orderType) order at \(stockPrice)$ each")

                    let symbol = activeSymbol

                    if orderType == "Limit" {
                        limitText = String(format: "%.2f", stockPrice) 
                        showLimitAlert = true
                        return
                    }

                    if tradeType == "Buy" {
                        Task {
                            let success = await stockManager.buyStock(
                                symbol: symbol,
                                in: context,
                                shares: shares,
                                executionPrice: stockPrice
                            )

                            if success {
                                showSuccessAlert = true
                            } else {
                                showInsufficientFundsAlert = true
                            }
                        }
                    } else { // Sell
                        let success = stockManager.sellStock(
                            symbol: symbol,
                            in: context,
                            shares: shares,
                            executionPrice: stockPrice
                        )
                        if success {
                            showSuccessAlert = true
                        } else {
                            showInsufficientSharesAlert = true
                        }
                    }

                }) {
                    Text("Place order")
                        .font(.system(size: 22, weight: .medium, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.glass)
                .disabled(!isSharesValid || activeSymbol.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
        .navigationBarHidden(false)

        .onAppear {
            if let stock = stockManager.selectedStock {
                stockCode = stock.code
                stockPrice = stock.current
                selectedSymbolInPicker = stock.code
                return
            }

            if let sym = stockManager.selectedSymbol ?? stockManager.selectedStockCode, !sym.isEmpty {
                stockCode = sym
                selectedSymbolInPicker = sym
                if let price = stockManager.selectedStockPrice {
                    stockPrice = price
                }
            } else if let first = watchlistStocks.first {
                stockCode = first.code
                stockPrice = first.current
                selectedSymbolInPicker = first.code

                stockManager.selectedStock = nil
                stockManager.selectedSymbol = first.code
                stockManager.selectedName = first.name
                stockManager.selectedStockCode = first.code
                stockManager.selectedStockPrice = first.current
            }
        }
        .onTapGesture {
            sharesFieldFocused = false
        }

        .onChange(of: selectedSymbolInPicker) { _, newSymbol in
            guard !newSymbol.isEmpty else { return }
            stockCode = newSymbol

            if let w = watchlistStocks.first(where: { $0.code == newSymbol }) {
                stockPrice = w.current

                stockManager.selectedStock = nil
                stockManager.selectedSymbol = w.code
                stockManager.selectedName = w.name
                stockManager.selectedStockCode = w.code
                stockManager.selectedStockPrice = w.current
            } else {
                stockManager.selectedSymbol = newSymbol
                stockManager.selectedStockCode = newSymbol
                stockManager.selectedStockPrice = stockPrice
            }
        }

        .alert("Insufficient Funds", isPresented: $showInsufficientFundsAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You do not have enough balance for this purchase.")
        }
        .alert("Order Placed", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your order was successfully completed.")
        }
        .alert("Not Enough Shares", isPresented: $showInsufficientSharesAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You don’t have enough shares of this stock to sell that amount.")
        }
        .alert("Limit Price", isPresented: $showLimitAlert) {
            TextField("Enter limit price", text: $limitText)
                .keyboardType(.decimalPad)

            Button("Place Limit Order") {
                let symbol = activeSymbol

                let name = stockManager.selectedStock?.name
                    ?? stockManager.selectedName
                    ?? symbol

                let limitPrice = Double(limitText.replacingOccurrences(of: ",", with: ".")) ?? 0

                let ok = stockManager.placeLimitOrder(
                    symbol: symbol,
                    name: name,
                    side: tradeType,
                    shares: shares,
                    limitPrice: limitPrice,
                    in: context
                )

                if ok {
                    showSuccessAlert = true
                } else {
                    showLimitFailedAlert = true
                }
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Put the value of the stock that you want to \(tradeType.lowercased()) at.")
        }
        .alert("Limit Order Failed", isPresented: $showLimitFailedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(tradeType == "Buy"
                 ? "Not enough available cash to place this limit buy."
                 : "Not enough available shares to place this limit sell.")
        }
    }
}

#Preview {
    TradeView()
        .environmentObject(StockManager())
}

