import SwiftUI

struct ContentView: View {
    var onStart: () -> Void = {}
    var body: some View {
        TabView {
            
            WatchlistView()
                .tabItem {
                    Label("", systemImage: "bookmark")
                }
            BajtlikView()
                .tabItem {
                    Label("", systemImage: "wallet.bifold")
                }
            TradeView()
                .tabItem {
                    Label("", systemImage: "repeat")
                }
            SettingView()
                .tabItem {
                    Label("", systemImage: "gearshape")
                    
                }
        }
    }
}

#Preview {
    ContentView()
}
