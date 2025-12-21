import SwiftUI
import SwiftData

struct TradeView: View {
    @EnvironmentObject var stockManager: StockManager
    @Environment(\.modelContext) private var context

    @Query(sort: \WatchlistItem.code)
    private var watchlistStocks: [WatchlistItem]

    @StateObject private var viewModel = TradeViewModel()
    @FocusState private var sharesFieldFocused: Bool

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
                        Text(viewModel.stockCode)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    } else {
                        HStack(spacing: 10) {

                            Group {
                                if let url = viewModel.logoURL {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable().scaledToFit()
                                        case .failure(_):
                                            Image(systemName: "building.2")
                                                .resizable().scaledToFit()
                                                .foregroundColor(.secondary)
                                        default:
                                            ProgressView()
                                        }
                                    }
                                } else {
                                    Image(systemName: "building.2")
                                        .resizable().scaledToFit()
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                            Picker("", selection: $viewModel.selectedSymbolInPicker) {
                                ForEach(watchlistStocks, id: \.code) { item in
                                    Text(item.code).tag(item.code)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                        }
                    }
                }

                Picker("Trade Type", selection: $viewModel.tradeType) {
                    Text("Sell").tag("Sell")
                    Text("Buy").tag("Buy")
                }
                .pickerStyle(.segmented)
                .scaleEffect(2)
                .frame(height: 40)
                .padding(.horizontal, 100)

                Picker("Order Type", selection: $viewModel.orderType) {
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
                    Text(String(format: "$%.2f", viewModel.stockPrice))
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                }

                HStack {
                    Text("Shares")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                    Spacer()

                    TextField("", value: $viewModel.shares, formatter: TradeViewModel.sharesFormatter)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)
                        .focused($sharesFieldFocused)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") { sharesFieldFocused = false }
                            }
                        }
                }

                HStack {
                    Text("Estimated cost")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                    Spacer()
                    Text(String(format: "$%.2f", viewModel.estimatedCost))
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
                    viewModel.placeOrder(stockManager: stockManager, context: context)
                }) {
                    Text("Place order")
                        .font(.system(size: 22, weight: .medium, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.glass)
                .disabled(!viewModel.isSharesValid || viewModel.activeSymbol(stockManager: stockManager).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
        .navigationBarHidden(false)
        .onAppear {
            viewModel.onAppear(stockManager: stockManager, watchlistStocks: watchlistStocks)
        }
        .onTapGesture {
            sharesFieldFocused = false
        }
        .onChange(of: viewModel.selectedSymbolInPicker) { _, newSymbol in
            viewModel.onSymbolChanged(newSymbol, stockManager: stockManager, watchlistStocks: watchlistStocks)
        }

        .alert("Insufficient Funds", isPresented: $viewModel.showInsufficientFundsAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You do not have enough balance for this purchase.")
        }
        .alert("Order Placed", isPresented: $viewModel.showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your order was successfully completed.")
        }
        .alert("Not Enough Shares", isPresented: $viewModel.showInsufficientSharesAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You don’t have enough shares of this stock to sell that amount.")
        }

        .alert("Limit Price", isPresented: $viewModel.showLimitAlert) {
            TextField("Enter limit price", text: $viewModel.limitText)
                .keyboardType(.decimalPad)

            Button("Place Limit Order") {
                viewModel.placeLimitOrderConfirmed(stockManager: stockManager, context: context)
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Put the value of the stock that you want to \(viewModel.tradeType.lowercased()) at.")
        }

        .alert("Limit Order Failed", isPresented: $viewModel.showLimitFailedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.tradeType == "Buy"
                 ? "Not enough available cash to place this limit buy."
                 : "Not enough available shares to place this limit sell.")
        }

        .alert("Trade Result", isPresented: $viewModel.showSellPLAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            let pl = viewModel.lastSellPL
            Text(pl >= 0
                 ? "You sold \(viewModel.lastSellSymbol) with a profit of $\(String(format: "%.2f", pl))."
                 : "You sold \(viewModel.lastSellSymbol) with a loss of $\(String(format: "%.2f", abs(pl))).")
        }
    }
}

#Preview {
    TradeView()
        .environmentObject(StockManager())
}

