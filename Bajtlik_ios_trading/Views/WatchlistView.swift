import SwiftUI
import SwiftData

struct WatchlistView: View {
    @EnvironmentObject var stockManager: StockManager
    @Environment(\.modelContext) private var context

    @Query(sort: \WatchlistItem.code)
    private var stocks: [WatchlistItem]

    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @StateObject private var viewModel = WatchlistViewModel()

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
                        viewModel.toggleSearchBar()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isDarkMode ? Color.black : Color.white)
                            .padding(10)
                            .background(Color.primary)
                            .clipShape(Circle())
                    }

                    Button {
                        viewModel.showSearchField = true
                    } label: {
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
                            viewModel.addSymbol(stockManager: stockManager, context: context)
                        }

                        Button("Cancel", role: .cancel) {
                            viewModel.cancelAdd()
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
                        StockCardWatchlist(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.openDetails(for: item, stockManager: stockManager)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    viewModel.remove(item, stockManager: stockManager, context: context)
                                } label: {
                                    Image(uiImage: UIImage(systemName: "trash")!
                                        .withTintColor(.red, renderingMode: .alwaysOriginal))
                                    .font(.system(size: 14, weight: .semibold))
                                }
                                .tint(.clear)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .navigationDestination(item: $viewModel.selectedStockForDetails) { item in
                    DetailedStockView()
                        .environmentObject(stockManager)
                        .onAppear {
                            stockManager.select(watchlist: item)
                            viewModel.refreshWatchlist(stocks: stocks, stockManager: stockManager, context: context)
                        }
                        .refreshable {
                            await stockManager.refreshWatchlistStocks(stocks: stocks, in: context)
                        }
                }
            }
        }
    }
}

