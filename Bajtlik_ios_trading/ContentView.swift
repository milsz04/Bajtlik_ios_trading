import SwiftUI

struct ContentView: View {
    @EnvironmentObject var stockManager: StockManager

    var body: some View {
        TabView {
            NavigationStack{
                WatchlistView()
            }
                .tabItem {
                    Label("", systemImage: "bookmark")
                }
            NavigationStack {
                BajtlikView()
            }
                .tabItem {
                    Label("", systemImage: "wallet.bifold")
                }
            NavigationStack{
                TradeView()
            }
                .tabItem {
                    Label("", systemImage: "repeat")
                }
            NavigationStack {
                SettingView()
            }
                .tabItem {
                    Label("", systemImage: "gearshape")
                    
                }
                
        }
        .tabViewStyle(.automatic)
        
    }
}

#Preview {
    ContentView()
        .environmentObject(StockManager())
}
