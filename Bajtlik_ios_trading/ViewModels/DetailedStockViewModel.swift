import SwiftUI
import SwiftData
import Foundation
import Combine

final class DetailedStockViewModel: ObservableObject {
    
    @Published var chartData: [PricePoint] = []
    @Published var isLoadingChart = false
    @Published var chartError: String?
}

