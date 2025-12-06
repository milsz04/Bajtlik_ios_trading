import SwiftUI
import SwiftData

struct WatchlistView: View {
    @EnvironmentObject var stockManager: StockManager
    @Environment(\.modelContext) private var context
    @Query(sort: \StockItem.code) private var stocks: [StockItem]
    
    @StateObject private var fetcher = StockFetcher()
    @State private var showSearchField = false
    @State private var stockSymbol = ""
    
    @State private var showSearchBar = false
    @State private var searchText = ""
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    private var filteredStocks: [StockItem] {
        guard !searchText.isEmpty else { return stocks }
        return stocks.filter { item in
            item.name.lowercased().contains(searchText.lowercased()) ||
            item.code.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Watchlist")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.easeInOut) {
                            showSearchBar.toggle()
                            if !showSearchBar {
                                searchText = ""
                            }
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isDarkMode ? Color.black : Color.white )
                            .padding(10)
                            .background(Color.primary
                            )
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        showSearchField = true
                    }) {
                        Label("", systemImage: "plus.circle.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(Color.primary)
                            .padding(.horizontal, 10)
                    }
                    .alert("Add Stock Symbol", isPresented: $showSearchField) {
                        TextField("Enter symbol (e.g. AAPL)", text: $stockSymbol)
                        Button("Add") {
                            Task {
                                await stockManager.addStock(symbol: stockSymbol, in: context)
                                stockSymbol = ""
                            }
                        }
                        Button("Cancel", role: .cancel) {
                            stockSymbol = ""
                        }
                    } message: {
                        Text("Type the stock symbol you want to add to your watchlist.")
                    }
                }
                
                if showSearchBar {
                    TextField("Search saved stocks…", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(10)
                        .background(isDarkMode ? Color.black : Color.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(filteredStocks) { item in
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
                    .padding(.bottom, .zero)
                }
            }
        }
    }
}

