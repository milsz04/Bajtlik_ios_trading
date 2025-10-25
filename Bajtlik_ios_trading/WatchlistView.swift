import SwiftUI

struct WatchlistView: View {
    let items = [
        StockItem(name: "ALLEGR", market: "GPW", price: "33,41", change: 0.67),
        StockItem(name: "ALLERO", market: "NSDAQ", price: "33,41", change: 0.67),
        StockItem(name: "ALLEGRO", market: "NSDAQ", price: "67,67", change: -0.67),
        StockItem(name: "ALLEGR", market: "GPW", price: "33,41", change: 0.67),
        StockItem(name: "ALLERO", market: "NSDAQ", price: "33,41", change: 0.67),
        StockItem(name: "ALLEGRO", market: "NSDAQ", price: "67,67", change: -0.67),
        StockItem(name: "ALLEGR", market: "GPW", price: "33,41", change: 0.67),
        StockItem(name: "ALLERO", market: "NSDAQ", price: "33,41", change: 0.67),
        StockItem(name: "ALLEGRO", market: "NSDAQ", price: "67,67", change: -0.67),
        StockItem(name: "ALLEGR", market: "GPW", price: "33,41", change: 0.67)
    ]
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                HStack{
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
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.white))
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 3)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                    }
                    .padding()

                }
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(items) { item in
                            StockCard(item: item)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, .zero)
                    
                }
                
                Spacer()
                
                
            }
        }
    
    }
}

struct StockItem: Identifiable {
    let id = UUID()
    let name: String
    let market: String
    let price: String
    let change: Double
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
        .onTapGesture {
            print(item.name)
        }
    }
}

#Preview {
    WatchlistView()
}
