import SwiftUI

struct BajtlikView: View {
    @EnvironmentObject var stockManager: StockManager
    
    @State private var bajtlikVal = 12400.02
    @State private var balance = 1100.09
    @State private var shares = 1
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Bajtlik")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.top, 20)
                
                Text("Bajtlik Value")
                    .font(.system(size: 40, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.top, 20)
                
                Text("\(bajtlikVal, specifier: "$%.2f")")
                    .font(.system(size: 30, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.top, 10)
                
                Text("Available")
                    .font(.system(size: 40, design: .monospaced))
                    .foregroundColor(.black)
                
                Text("\(balance, specifier: "$%.2f")")
                    .font(.system(size: 30, design: .monospaced))
                    .foregroundColor(.black)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(stockManager.stocks) { item in
                            NavigationLink(
                                destination: DetailedStockView()
                                    .environmentObject(stockManager)
                                    .onAppear {
                                        stockManager.selectedStock = item
                                    }
                            ) {
                                StockCardBajtlik(item: item)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .padding()
        }
        .navigationBarHidden(false)
    }
}

struct StockCardBajtlik: View {
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
        BajtlikView()
            .environmentObject(StockManager())
    }
}
