import SwiftUI
import SwiftData

struct BajtlikView: View {
    @EnvironmentObject var stockManager: StockManager
    @Environment(\.modelContext) private var context

    @Query(sort: \StockItem.code) private var stocks: [StockItem]
    
    @StateObject private var viewModel = BajtlikViewModel()
    
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                
                Text("Bajtlik")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                
                Text("Value")
                    .font(.system(size: 40, design: .monospaced))

                Text("\(viewModel.bajtlikVal, format: .currency(code: "USD"))")
                    .font(.system(size: 30, design: .monospaced))

                Text("Available")
                    .font(.system(size: 40, design: .monospaced))

                Text("\(stockManager.balance, format: .currency(code: "USD"))")
                    .font(.system(size: 30, design: .monospaced))

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(stocks) { item in
                            NavigationLink(
                                destination: DetailedStockView()
                                    .environmentObject(stockManager)
                                    .onAppear { stockManager.selectedStock = item }
                            ) {
                                StockCardBajtlik(item: item)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)
        }
        .navigationBarHidden(false)
    }
}
