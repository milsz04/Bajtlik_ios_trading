import SwiftUI
import Combine

@MainActor
class StockLineChartViewModel: ObservableObject {
    @Published var visibleData: [PricePoint] = []
    @Published var yMinPadded: Double = 0
    @Published var yMaxPadded: Double = 0
    @Published var sevenDayIndexed: [(index: Int, point: PricePoint)] = []
    @Published var sevenDayTickIndices: [Int] = []

    private let range: ChartTimeRange

    init(data: [PricePoint], range: ChartTimeRange) {
        self.range = range
        prepareData(data)
    }

    private func prepareData(_ data: [PricePoint]) {
        let sortedData = data.sorted { $0.time < $1.time }
        visibleData = filterVisibleData(sortedData)
        computeYAxisPadding()
        if range == .sevenDays {
            sevenDayIndexed = Array(visibleData.enumerated().map { ($0.offset, $0.element) })
            sevenDayTickIndices = computeSevenDayTickIndices()
        }
    }

    private func isInRegularSession(_ date: Date) -> Bool {
        let tz = TimeZone(identifier: "America/New_York") ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let comps = cal.dateComponents([.weekday, .hour], from: date)
        guard let weekday = comps.weekday, let hour = comps.hour else { return false }
        guard (2...6).contains(weekday) else { return false }
        return hour >= 9 && hour < 16
    }

    private func filterVisibleData(_ sortedData: [PricePoint]) -> [PricePoint] {
        guard let lastTime = sortedData.last?.time else { return [] }
        let cal = Calendar.current

        let start: Date
        switch range {
        case .oneDay:
            start = cal.startOfDay(for: lastTime)
        case .sevenDays:
            start = cal.date(byAdding: .day, value: -7, to: lastTime) ?? sortedData.first!.time
        case .oneMonth:
            start = cal.date(byAdding: .month, value: -1, to: lastTime) ?? sortedData.first!.time
        case .sixMonths:
            start = cal.date(byAdding: .month, value: -6, to: lastTime) ?? sortedData.first!.time
        case .oneYear:
            start = cal.date(byAdding: .year, value: -1, to: lastTime) ?? sortedData.first!.time
        }

        let windowFiltered = sortedData.filter { $0.time >= start && $0.time <= lastTime }

        switch range {
        case .oneDay, .sevenDays:
            let sessionFiltered = windowFiltered.filter { isInRegularSession($0.time) }
            return sessionFiltered.isEmpty ? windowFiltered : sessionFiltered
        default:
            return windowFiltered
        }
    }

    private func computeYAxisPadding() {
        let prices = visibleData.map(\.price)
        if let minV = prices.min(), let maxV = prices.max(), maxV > minV {
            let range = maxV - minV
            let pad = max(range * 0.02, 0.01)
            yMinPadded = minV - pad
            yMaxPadded = maxV + pad
        } else {
            let first = prices.first ?? 0
            yMinPadded = first - 1
            yMaxPadded = first + 1
        }
    }

    private func computeSevenDayTickIndices() -> [Int] {
        let cal = Calendar.current
        var result: [Int] = []

        for (i, p) in visibleData.enumerated() {
            let day = cal.startOfDay(for: p.time)
            if result.isEmpty {
                result.append(i)
            } else {
                let lastIndex = result.last!
                let lastDay = cal.startOfDay(for: visibleData[lastIndex].time)
                if day != lastDay { result.append(i) }
            }
        }
        return result
    }

    var xDomainDate: ClosedRange<Date> {
        guard let first = visibleData.first?.time,
              let last  = visibleData.last?.time else {
            let now = Date()
            return now.addingTimeInterval(-3600)...now
        }
        return first...last
    }

    var xDomainIndex: ClosedRange<Int> {
        let maxIndex = max(sevenDayIndexed.count - 1, 0)
        return 0...maxIndex
    }
}
