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

    private var totalValue: Double {
        stockManager.balance + stocks.reduce(0) { $0 + $1.marketValue }
    }

    private var totalUnrealizedPL: Double {
        stocks.reduce(0) { $0 + $1.unrealizedPL }
    }

    private var isProfit: Bool {
        totalUnrealizedPL >= 0
    }

    var body: some View {
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
                        
                        Image(systemName: isProfit ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(isProfit ? .green : .red)
                        
                        Text("\(isProfit ? "+" : "")\(totalUnrealizedPL, format: .currency(code: "USD"))")
                            .font(.system(size: 22, weight: .semibold, design: .monospaced))
                            .foregroundColor(isProfit ? .green : .red)
                    }
                    
                    Text("\(totalValue, format: .currency(code: "USD"))")
                        .font(.system(size: 30, design: .monospaced))
                    
                    Text("Available")
                        .font(.system(size: 40, design: .monospaced))
                    
                    Text("\(stockManager.availableCash, format: .currency(code: "USD"))")
                        .font(.system(size: 30, design: .monospaced))
                    VStack(spacing: 16) {
                        
                        // OWNED STOCKS
                        ForEach(stocks) { item in
                            NavigationLink(
                                destination: DetailedStockView()
                                    .environmentObject(stockManager)
                                    .onAppear {
                                        stockManager.select(stock: item)
                                        Task { await stockManager.processLimitOrders(in: context) }
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
                await stockManager.refreshAllStocks(stocks: stocks, in: context)
            }
            .refreshable {
                        await stockManager.refreshAllStocks(stocks: stocks, in: context)
        }
        .navigationBarHidden(false)
    }
}

