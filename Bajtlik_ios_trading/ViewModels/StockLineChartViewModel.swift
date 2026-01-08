import SwiftUI
import Foundation
import Combine

@MainActor
final class StockLineChartViewModel: ObservableObject {

    @Published private(set) var visibleData: [PricePoint] = []
    @Published private(set) var sevenDayIndexed: [(index: Int, point: PricePoint)] = []
    @Published private(set) var sevenDayTickIndices: [Int] = []

    @Published private(set) var yMinPadded: Double = 0
    @Published private(set) var yMaxPadded: Double = 0

    private(set) var range: ChartTimeRange

    init(data: [PricePoint], range: ChartTimeRange) {
        self.range = range
        prepareData(data)
    }

    func update(data: [PricePoint], range: ChartTimeRange) {
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
        } else {
            sevenDayIndexed = []
            sevenDayTickIndices = []
        }
    }

    private func isInRegularSession(_ date: Date) -> Bool {
        let tz = TimeZone(identifier: "America/New_York") ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz

        let comps = cal.dateComponents([.weekday, .hour], from: date)
        guard let weekday = comps.weekday, let hour = comps.hour else { return false }
        guard (2...6).contains(weekday) else { return false }    // pon–pt
        return hour >= 9 && hour < 16
    }

    private func filterVisibleData(_ all: [PricePoint]) -> [PricePoint] {
        guard let lastTime = all.last?.time else { return [] }
        if all.count <= 1 { return all }

        let cal = Calendar.current
        let start: Date

        switch range {
        case .oneDay:
            start = cal.startOfDay(for: lastTime)
        case .sevenDays:
            start = cal.date(byAdding: .day, value: -7, to: lastTime) ?? all.first!.time
        case .oneMonth:
            start = cal.date(byAdding: .month, value: -1, to: lastTime) ?? all.first!.time
        case .sixMonths:
            start = cal.date(byAdding: .month, value: -6, to: lastTime) ?? all.first!.time
        case .oneYear:
            start = cal.date(byAdding: .year, value: -1, to: lastTime) ?? all.first!.time
        }

        let windowFiltered = all.filter { p in
            p.time >= start && p.time <= lastTime
        }

        let sessionFiltered: [PricePoint]
        switch range {
        case .oneDay, .sevenDays:
            sessionFiltered = windowFiltered.filter { isInRegularSession($0.time) }
        default:
            sessionFiltered = windowFiltered
        }

        return sessionFiltered.isEmpty ? windowFiltered : sessionFiltered
    }

    private func computeYAxisPadding() {
        let prices = visibleData.map(\.price)
        guard let minV = prices.min(), let maxV = prices.max(), maxV > minV else {
            let base = prices.first ?? 0
            yMinPadded = base - 1
            yMaxPadded = base + 1
            return
        }

        let range = maxV - minV
        let pad = max(range * 0.02, 0.01)
        yMinPadded = minV - pad
        yMaxPadded = maxV + pad
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
                if day != lastDay {
                    result.append(i)
                }
            }
        }
        return result
    }

    // MARK: - Właściwości używane przez View

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

    var xLabelCount: Int {
        5
    }

    var sevenDayTickIndicesLimited: [Int] {
        let ticks = sevenDayTickIndices
        let maxLabels = 4

        guard ticks.count > maxLabels, maxLabels > 1 else {
            return ticks
        }

        let step = Double(ticks.count - 1) / Double(maxLabels - 1)

        return (0..<maxLabels).map { i in
            let idx = Int(round(Double(i) * step))
            return ticks[idx]
        }
    }

    var lastVisiblePoint: PricePoint? {
        visibleData.last
    }

    var lastVisibleSevenDayIndex: Int? {
        sevenDayIndexed.last?.index
    }
}
