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
        guard (2...6).contains(weekday) else { return false }
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
    
    private var sevenDayIndexed: [(index: Int, point: PricePoint)] {
        guard range == .sevenDays else { return [] }
        return Array(visibleData.enumerated().map { ($0.offset, $0.element) })
    }
    
    private var sevenDayTickIndices: [Int] {
        guard range == .sevenDays else { return [] }
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
        case .oneDay:
            return 5
        case .sevenDays:
            return 7
        case .oneMonth:
            return 6
        case .sixMonths:
            return 5
        case .oneYear:
            return 6
        }
    }
    
    private var yMinPadded: Double {
        let prices = visibleData.map(\.price)
        guard let minV = prices.min(), let maxV = prices.max(), maxV > minV else {
            return (prices.first ?? 0) - 1
        }
        let range = maxV - minV
        let pad = max(range * 0.02, 0.01)
        return minV - pad
    }
    
    private var yMaxPadded: Double {
        let prices = visibleData.map(\.price)
        guard let minV = prices.min(), let maxV = prices.max(), maxV > minV else {
            return (prices.first ?? 0) + 1
        }
        let range = maxV - minV
        let pad = max(range * 0.02, 0.01)
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
                AxisMarks(values: sevenDayTickIndices) { value in
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
                            case .oneMonth, .sevenDays:
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

private struct XScaleModifier: ViewModifier {
    let range: ChartTimeRange
    let xDomainDate: ClosedRange<Date>
    let xDomainIndex: ClosedRange<Int>
    
    func body(content: Content) -> some View {
        switch range {
        case .sevenDays:
            content.chartXScale(domain: xDomainIndex)
        default:
            content.chartXScale(domain: xDomainDate)
        }
    }
}

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

