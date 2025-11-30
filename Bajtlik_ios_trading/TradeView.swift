import SwiftUI

struct TradeView: View {
    @EnvironmentObject var stockManager: StockManager
    
    @State private var tradeType = "Sell"
    @State private var orderType = "Market"
    @State private var shares: Double = 1.00
    @State private var stockPrice: Double = 150.2
    @State private var stockCode = "firmaA"
    
    @State private var showInsufficientFundsAlert = false
    @State private var showSuccessAlert = false
    var estimatedCost: Double {
        shares * stockPrice
    }
    private static let sharesFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.minimum = 0.01
        return formatter
    }()
    
    private var isSharesValid: Bool {
        shares >= 0.01
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                HStack{
                    Text("Trade")
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.top, 0)
                    Spacer()
                    Text(stockCode)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                }
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
                    TextField("", value: $shares, formatter: Self.sharesFormatter)
                        .keyboardType(.decimalPad)
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
                    Text(String(format: "$%.2f", stockManager.balance))
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                }
                
                Spacer()
                
                
                Button(action: {
                    print("\(tradeType) \(shares) shares with \(orderType) order at \(stockPrice)$ each")
                    
                    switch tradeType {
                    case "Buy":
                        let success = stockManager.tryBuy(shares: shares, pricePerShare: stockPrice)
                        if success {
                            showSuccessAlert = true
                        } else {
                            showInsufficientFundsAlert = true
                        }
                        
                    case "Sell":
                        // Here you can add selling logic later (e.g. increase balance)
                        print("Sell logic not implemented yet")
                        
                    default:
                        break
                    }
                }) {
                    Text("Place order")
                        .font(.system(size: 22, weight: .medium, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                        .foregroundColor(.black)
                }
                .buttonStyle(.glass)
                .alert("Insufficient Funds", isPresented: $showInsufficientFundsAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("You don't have enough available balance to complete this purchase.")
                }
                .alert("Order Placed", isPresented: $showSuccessAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Your buy order has been executed.")
                }
                
                .padding()
            }
            .navigationBarHidden(false)
            .onAppear {
                if let stock = stockManager.selectedStock {
                    stockPrice = stock.current
                    stockCode = stock.code
                    
                }
            }
        }
    }
}

#Preview {
    TradeView()
        .environmentObject(StockManager())
}
