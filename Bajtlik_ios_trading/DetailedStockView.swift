import SwiftUI

struct DetailedStockView: View {
    @EnvironmentObject var stockManager: StockManager
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            if let stock = stockManager.selectedStock {
                VStack(alignment: .leading, spacing: 12) {
                    HStack{
                        Text(stock.code)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                        Spacer()
                        NavigationLink(destination: TradeView()) {
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
                    Text("Market: \(stock.market)")
                        .font(.system(size: 20, design: .monospaced))
                    
                    Text("Price: \(stock.price)")
                        .font(.system(size: 20, design: .monospaced))
                    
                    Text("Change: \(stock.change > 0 ? "+" : "")\(String(stock.change))%")
                        .font(.system(size: 20, weight: .regular, design: .monospaced))
                        .foregroundColor(stock.change > 0 ? .green : .red)
                    
                    Spacer()
                    Divider()
                    HStack{
                        Text("Open")
                            .font(.system(size: 24, design: .monospaced))
                            .foregroundColor(Color(.label))
                        Spacer()
                        Text("150.23")
                            .font(.system(size: 24, design: .monospaced))
                            .foregroundColor(Color(.label))
                    }
                    Divider()
                    HStack{
                        Text("High")
                            .font(.system(size: 24, design: .monospaced))
                            .foregroundColor(Color(.label))
                        Spacer()
                        Text("150.23")
                            .font(.system(size: 24, design: .monospaced))
                            .foregroundColor(Color(.label))
                    }
                    Divider()
                    HStack{
                        Text("Low")
                            .font(.system(size: 24, design: .monospaced))
                            .foregroundColor(Color(.label))
                        Spacer()
                        Text("150.23")
                            .font(.system(size: 24, design: .monospaced))
                            .foregroundColor(Color(.label))
                    }
                    Divider()
                    HStack{
                        Text("Volume")
                            .font(.system(size: 24, design: .monospaced))
                            .foregroundColor(Color(.label))
                        Spacer()
                        Text("150.23")
                            .font(.system(size: 24, design: .monospaced))
                            .foregroundColor(Color(.label))
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
    DetailedStockView()
        .environmentObject(StockManager())
}
