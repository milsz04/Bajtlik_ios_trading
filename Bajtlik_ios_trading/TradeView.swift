import SwiftUI

struct TradeView: View {
    @EnvironmentObject var stockManager: StockManager
    
    @State private var tradeType = "Sell"
    @State private var orderType = "Market"
    @State private var shares = 1
    @State private var stockPrice: Double = 150.25
    var estimatedCost: Double {
        Double(shares) * stockPrice
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Trade")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.top, 20)
                
                Picker("Trade Type", selection: $tradeType) {
                    Text("Sell").tag("Sell")
                    Text("Buy").tag("Buy")
                }
                .pickerStyle(.segmented)
                .scaleEffect(2)
                .frame(height: 40)
                .padding(.horizontal,100)
                
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
                    TextField("", value: $shares, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)
                    
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
                    Text("$1000.00")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                }
                
                Spacer()
                
                Button(action: {
                    print("\(tradeType) \(shares) shares with \(orderType) order at \(stockPrice)$ each")
                }) {
                    Text("Place order")
                        .font(.system(size: 22, weight: .medium, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                        .foregroundColor(.black)
                }
                .buttonStyle(.glass)
            }
            .padding()
        }
        .navigationBarHidden(false)
        .onAppear {
            if let stock = stockManager.selectedStock {
                stockPrice = stock.current
                
            }
        }
    }
}

#Preview {
    TradeView()
        .environmentObject(StockManager())
}
