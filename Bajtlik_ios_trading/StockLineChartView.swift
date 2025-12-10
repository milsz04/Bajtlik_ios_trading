import SwiftUI
import Charts

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

struct StockLineChart: View {
    let data: [PricePoint]
    let isPositive: Bool
    let range: ChartTimeRange

    private var sortedData: [PricePoint] {
        data.sorted { $0.time < $1.time }
    }

    private func isInRegularSession(_ date: Date) -> Bool {
        let tz = TimeZone(identifier: "America/New_York") ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz

        let comps = cal.dateComponents([.weekday, .hour], from: date)
        guard let weekday = comps.weekday, let hour = comps.hour else { return false }
        // Monday (2) to Friday (6)
        guard (2...6).contains(weekday) else { return false }
        // 9:00 AM to 3:59 PM (New York Time)
        return hour >= 9 && hour < 16
    }

    private var visibleData: [PricePoint] {
        let all = sortedData
        guard let lastTime = all.last?.time else { return [] }
        if all.count <= 1 { return all }

        let cal = Calendar.current

        let start: Date
        switch range {
        case .oneDay:
            // Start of the last data point's day
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
            // Filter out pre/post market data for short ranges
            sessionFiltered = windowFiltered.filter { isInRegularSession($0.time) }
        default:
            sessionFiltered = windowFiltered
        }

        // Use windowFiltered if sessionFiltered is empty (e.g., if data only has pre-market times for one day)
        return sessionFiltered.isEmpty ? windowFiltered : sessionFiltered
    }

    // Used for .sevenDays chart, which maps time to a simple index for continuous display
    private var sevenDayIndexed: [(index: Int, point: PricePoint)] {
        guard range == .sevenDays else { return [] }
        return Array(visibleData.enumerated().map { ($0.offset, $0.element) })
    }

    // Used for .sevenDays chart X-Axis ticks (indices corresponding to the start of each day)
    private var sevenDayTickIndices: [Int] {
        guard range == .sevenDays else { return [] }
        let cal = Calendar.current
        var result: [Int] = []

        for (i, p) in visibleData.enumerated() {
            let day = cal.startOfDay(for: p.time)

            if result.isEmpty {
                // Always include the first point
                result.append(i)
            } else {
                let lastIndex = result.last!
                let lastDay = cal.startOfDay(for: visibleData[lastIndex].time)
                // Add an index if it's the start of a new day
                if day != lastDay {
                    result.append(i)
                }
            }
        }
        return result
    }

    private var xDomainDate: ClosedRange<Date> {
        guard let first = visibleData.first?.time,
              let last  = visibleData.last?.time else {
            let now = Date()
            return now.addingTimeInterval(-3600)...now
        }
        return first ... last
    }

    private var xDomainIndex: ClosedRange<Int> {
        let maxIndex = max(sevenDayIndexed.count - 1, 0)
        return 0 ... maxIndex
    }

    private var xLabelCount: Int {
        switch range {
        case .oneDay: return 5
        case .sevenDays: return 5 // Ignored, custom logic used for .sevenDays
        case .oneMonth: return 5
        case .sixMonths: return 5
        case .oneYear: return 5
        }
    }

    // Limits the number of day ticks for the seven-day view to prevent clutter
    private var sevenDayTickIndicesLimited: [Int] {
        let ticks = sevenDayTickIndices
        let maxLabels = 4

        guard ticks.count > maxLabels, maxLabels > 1 else {
            return ticks
        }

        // Calculate step to distribute the remaining labels evenly
        let step = Double(ticks.count - 1) / Double(maxLabels - 1)

        return (0..<maxLabels).map { i in
            let idx = Int(round(Double(i) * step))
            return ticks[idx]
        }
    }

    private var yMinPadded: Double {
        let prices = visibleData.map(\.price)
        guard let minV = prices.min(), let maxV = prices.max(), maxV > minV else {
            return (prices.first ?? 0) - 1
        }
        let range = maxV - minV
        let pad = max(range * 0.02, 0.01) // 2% padding, minimum 0.01
        return minV - pad
    }

    private var yMaxPadded: Double {
        let prices = visibleData.map(\.price)
        guard let minV = prices.min(), let maxV = prices.max(), maxV > minV else {
            return (prices.first ?? 0) + 1
        }
        let range = maxV - minV
        let pad = max(range * 0.02, 0.01) // 2% padding, minimum 0.01
        return maxV + pad
    }

    var body: some View {
        Chart {
            if range == .sevenDays {
                ForEach(sevenDayIndexed, id: \.point.id) { item in
                    LineMark(
                        x: .value("Index", item.index),
                        y: .value("Price", item.point.price)
                    )
                    .interpolationMethod(.linear)
                    .lineStyle(.init(lineWidth: 2))
                    .foregroundStyle(isPositive ? Color.green : Color.red)
                }

                ForEach(sevenDayIndexed, id: \.point.id) { item in
                    AreaMark(
                        x: .value("Index", item.index),
                        yStart: .value("Min", yMinPadded),
                        yEnd: .value("Price", item.point.price)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                (isPositive ? Color.green : Color.red).opacity(0.30),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            } else {
                ForEach(visibleData) { p in
                    LineMark(
                        x: .value("Time", p.time),
                        y: .value("Price", p.price)
                    )
                    .interpolationMethod(.linear)
                    .lineStyle(.init(lineWidth: 2))
                    .foregroundStyle(isPositive ? Color.green : Color.red)
                }

                ForEach(visibleData) { p in
                    AreaMark(
                        x: .value("Time", p.time),
                        yStart: .value("Min", yMinPadded),
                        yEnd: .value("Price", p.price)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                (isPositive ? Color.green : Color.red).opacity(0.30),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }

            // Current price marker
            if let last = visibleData.last {
                if range == .sevenDays {
                    if let lastIdx = sevenDayIndexed.last?.index {
                        PointMark(
                            x: .value("Index", lastIdx),
                            y: .value("Price", last.price)
                        )
                        .symbolSize(40)
                        .foregroundStyle(isPositive ? Color.green : Color.red)
                    }
                } else {
                    PointMark(
                        x: .value("Time", last.time),
                        y: .value("Price", last.price)
                    )
                    .symbolSize(40)
                    .foregroundStyle(isPositive ? Color.green : Color.red)

                    // Dashed rule for oneDay chart
                    if range == .oneDay {
                        RuleMark(
                            y: .value("Last price", last.price)
                        )
                        .lineStyle(.init(lineWidth: 2, dash: [6, 4]))
                        .foregroundStyle(.gray)
                    }
                }
            }
        }
        .modifier(XScaleModifier(range: range,
                                 xDomainDate: xDomainDate,
                                 xDomainIndex: xDomainIndex))
        .chartYScale(domain: yMinPadded ... yMaxPadded)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                if let y = value.as(Double.self) {
                    AxisValueLabel {
                        Text(String(format: "%.2f", y))
                    }
                }
            }
        }
        .chartXAxis {
            if range == .sevenDays {
                // Custom day-based ticks for 7-day view using indices
                AxisMarks(values: sevenDayTickIndicesLimited) { value in
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                    if let idx = value.as(Int.self),
                       idx >= 0,
                       idx < visibleData.count {
                        let date = visibleData[idx].time
                        AxisValueLabel {
                            Text(DateFormatter.ddMM.string(from: date))
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                    }
                }
            } else {
                // Automatic date-based ticks for all other ranges
                AxisMarks(
                    preset: .automatic,
                    position: .bottom,
                    values: .automatic(desiredCount: xLabelCount)
                ) { value in
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))

                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            switch range {
                            case .oneDay:
                                Text(DateFormatter.hhmm.string(from: date))
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            case .oneMonth, .sevenDays: // sevenDays case is handled above, but included for completeness/fallback
                                Text(DateFormatter.ddMM.string(from: date))
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            case .sixMonths, .oneYear:
                                Text(DateFormatter.MMM.string(from: date))
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
            }
        }
        .chartPlotStyle { plot in
            plot
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .frame(height: 260)
        .padding(.vertical, 4)
    }
}

// Custom ViewModifier to handle X-Scale based on ChartTimeRange
private struct XScaleModifier: ViewModifier {
    let range: ChartTimeRange
    let xDomainDate: ClosedRange<Date>
    let xDomainIndex: ClosedRange<Int>

    func body(content: Content) -> some View {
        switch range {
        case .sevenDays:
            // Use index as the X-axis for the 7-day view to prevent gaps for weekends/holidays
            content.chartXScale(domain:xDomainIndex)
        default:
            // Use date as the X-axis for all other time ranges
            content.chartXScale(domain: xDomainDate)
        }
    }
}

// DateFormatter extensions for cleaner axis labels
private extension DateFormatter {
    static let hhmm: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    static let ddMM: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f
    }()

    static let MMM: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()
}
