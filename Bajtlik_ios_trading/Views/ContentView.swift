import SwiftUI

struct ContentView: View {
    @EnvironmentObject var stockManager: StockManager
    @State private var showSearch = false
    @State private var searchText = ""
    
    
    let viewModel = BajtlikViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                WatchlistView()
                    .environmentObject(stockManager)
            }
            .tabItem {
                Label("", systemImage: "bookmark")
            }
            .tag(0)
            
            NavigationStack {
                BajtlikView()
                    .environmentObject(stockManager)
            }
            .tabItem {
                Label("", systemImage: "wallet.bifold")
            }
            .tag(1)
            
            NavigationStack {
                TradeView()
                    .environmentObject(stockManager)
            }
            .tabItem {
                Label("", systemImage: "repeat")
            }
            .tag(2)
            
            NavigationStack {
                SettingView()
                    .environmentObject(stockManager)
            }
            .tabItem {
                Label("", systemImage: "gearshape")
            }
            .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(StockManager())
}
