import SwiftUI

struct ContentView: View {
    @EnvironmentObject var stockManager: StockManager
    @State private var showSearch = false
    @State private var searchText = ""
    @SceneStorage("selectedTab") private var selectedTabIndex = 0

    var body: some View {
        TabView(selection: $selectedTabIndex) {
            Tab("", systemImage: "bookmark", value: 0){
                WatchlistView()
            }
            Tab("", systemImage: "wallet.bifold", value: 1){
                BajtlikView()
            }
            Tab("", systemImage: "repeat", value: 2){
                TradeView()
            }
            Tab("", systemImage: "gearshape", value: 3){
                SettingView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(StockManager())
}
