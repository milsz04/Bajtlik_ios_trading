import SwiftUI
import SwiftData

struct WatchlistView: View {
    @EnvironmentObject var stockManager: StockManager
    @Environment(\.modelContext) private var context
    @Query(sort: \StockItem.code) private var stocks: [StockItem]

    @StateObject private var fetcher = StockFetcher()
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var selectedStockForDetails: StockItem?

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
                            viewModel.showSearchBar.toggle()
                            if !viewModel.showSearchBar {
                                viewModel.searchText = ""
                            }
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isDarkMode ? Color.black : Color.white )
                            .padding(10)
                            .background(Color.primary)
                            .clipShape(Circle())
                    }

                    Button(action: {
                        viewModel.showSearchField = true
                    }) {
                        Label("", systemImage: "plus.circle.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(Color.primary)
                            .padding(.horizontal, 10)
                    }
                    .alert("Add Stock Symbol", isPresented: $viewModel.showSearchField) {
                        TextField("Enter symbol (e.g. AAPL)", text: $viewModel.stockSymbol)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                        Button("Add") {
                            Task {
                                await stockManager.addStock(query: viewModel.stockSymbol, in: context)
                                viewModel.stockSymbol = ""
                            }
                        }
                        Button("Cancel", role: .cancel) {
                            viewModel.stockSymbol = ""
                        }
                    } message: {
                        Text("Type the stock symbol you want to add to your watchlist.")
                    }
                }

                if viewModel.showSearchBar {
                    TextField("Search saved stocks…", text: $viewModel.searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(10)
                        .background(isDarkMode ? Color.black : Color.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                List {
                    ForEach(viewModel.filteredStocks(from: stocks)) { item in
                        StockCardBajtlik(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedStockForDetails = item
                                stockManager.selectedStock = item
                            }
                            .padding(.vertical, 8)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    stockManager.removeStock(item, in: context)
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)            // kolor koła
                                            .frame(width: 32, height: 32)
                                        
                                        Image(systemName: "trash")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .navigationDestination(item: $selectedStockForDetails) { item in
                    DetailedStockView()
                        .environmentObject(stockManager)
                        .onAppear { stockManager.selectedStock = item }
                }
            }
        }
    }
}
