import SwiftUI
import SwiftData

@main
struct Bajtlik_ios_tradingTestApp: App {
    @StateObject private var stockManager = StockManager()
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(stockManager)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .modelContainer(for: [StockItem.self, WatchlistItem.self])
    }
}
