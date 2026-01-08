import SwiftUI
import SwiftData

struct BajtlikView: View {
    @EnvironmentObject var stockManager: StockManager
    @Environment(\.modelContext) private var context

    @Query(filter: #Predicate<StockItem> { $0.sharesOwned > 0 }, sort: \StockItem.code)
    private var stocks: [StockItem]

    @Query(sort: \LimitOrder.createdAt)
    private var limitOrders: [LimitOrder]

    @StateObject private var viewModel = BajtlikViewModel()

    var body: some View {
        let s = viewModel.summary(balance: stockManager.balance, stocks: stocks)

        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Text("Bajtlik")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)

                ScrollView {
                    HStack(spacing: 10) {
                        Text("Value")
                            .font(.system(size: 40, design: .monospaced))

                        Image(systemName: s.isProfit ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(s.isProfit ? .green : .red)

                        Text("\(s.isProfit ? "+" : "")\(s.totalUnrealizedPL, format: .currency(code: "USD"))")
                            .font(.system(size: 22, weight: .semibold, design: .monospaced))
                            .foregroundColor(s.isProfit ? .green : .red)
                    }

                    Text("\(s.totalValue, format: .currency(code: "USD"))")
                        .font(.system(size: 30, design: .monospaced))

                    Text("Available")
                        .font(.system(size: 40, design: .monospaced))

                    Text("\(stockManager.availableCash, format: .currency(code: "USD"))")
                        .font(.system(size: 30, design: .monospaced))

                    VStack(spacing: 16) {

                        ForEach(stocks) { item in
                            NavigationLink(
                                destination: DetailedStockView()
                                    .environmentObject(stockManager)
                                    .onAppear {
                                        viewModel.openDetails(for: item, stockManager: stockManager, context: context)
                                    }
                            ) {
                                StockCardBajtlik(item: item)
                            }
                        }

                        if !limitOrders.isEmpty {
                            Text("Waiting positions")
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .padding(.top, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(spacing: 10) {
                                ForEach(limitOrders) { order in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(order.symbol) • \(order.side)")
                                                .font(.system(size: 18, weight: .bold, design: .monospaced))

                                            Text("Shares: \(order.shares, specifier: "%.2f") @ $\(order.limitPrice, specifier: "%.2f")")
                                                .font(.system(size: 14, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Button(role: .destructive) {
                                            stockManager.cancelLimitOrder(order, in: context)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray4))
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)
        }
        .task {
            await viewModel.refreshPortfolio(stocks: stocks, stockManager: stockManager, context: context)
        }
        .refreshable {
            await viewModel.refreshPortfolio(stocks: stocks, stockManager: stockManager, context: context)
        }
        .navigationBarHidden(false)
    }
}

