import SwiftUI

@main
struct Bajtlik_ios_tradingTestApp: App {
    @StateObject private var stockManager = StockManager()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(stockManager)
        }
    }
}
