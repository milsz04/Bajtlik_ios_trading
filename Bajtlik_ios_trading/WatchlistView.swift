import SwiftUI

struct WatchlistView: View {
    @EnvironmentObject var stockManager: StockManager
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Watchlist")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                    Spacer()
                    Button(action: {
                        print("Add new stock")
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal)
                    }
                    .buttonStyle(.glass)
                    .padding()
                }
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(stockManager.stocks) { item in
                            NavigationLink(
                                destination: DetailedStockView()
                                    .environmentObject(stockManager)
                                    .onAppear { stockManager.selectedStock = item }
                            ) {
                                StockCard(item: item)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, .zero)
                }
                
            }
        }
    }
}

struct StockCard: View {
    let item: StockItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundColor(.black)
                Text(item.market)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(item.price)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundColor(.black)
                Text("\(item.change > 0 ? "+" : "")\(String(item.change))%")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(item.change > 0 ? .green : .red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray4))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        )
    }
}

#Preview {
    NavigationStack {
        WatchlistView()
            .environmentObject(StockManager())
    }
}
