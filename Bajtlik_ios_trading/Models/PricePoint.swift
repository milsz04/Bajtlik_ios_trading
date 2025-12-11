import Foundation

struct PricePoint: Identifiable {
    let id = UUID()
    let time: Date
    let price: Double
}

enum ChartTimeRange {
    case oneDay
    case sevenDays
    case oneMonth
    case sixMonths
    case oneYear
}
