import SwiftUI
import Charts

struct StockLineChart: View {
    let data: [PricePoint]
    let isPositive: Bool
    let range: ChartTimeRange

    @StateObject private var vm: StockLineChartViewModel

    init(data: [PricePoint], isPositive: Bool, range: ChartTimeRange) {
        self.data = data
        self.isPositive = isPositive
        self.range = range
        _vm = StateObject(wrappedValue: StockLineChartViewModel(data: data, range: range))
    }

    var body: some View {
        Chart {
            if range == .sevenDays {
                ForEach(vm.sevenDayIndexed, id: \.point.id) { item in
                    LineMark(
                        x: .value("Index", item.index),
                        y: .value("Price", item.point.price)
                    )
                    .interpolationMethod(.linear)
                    .lineStyle(.init(lineWidth: 2))
                    .foregroundStyle(isPositive ? Color.green : Color.red)
                }

                ForEach(vm.sevenDayIndexed, id: \.point.id) { item in
                    AreaMark(
                        x: .value("Index", item.index),
                        yStart: .value("Min", vm.yMinPadded),
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
                ForEach(vm.visibleData) { p in
                    LineMark(
                        x: .value("Time", p.time),
                        y: .value("Price", p.price)
                    )
                    .interpolationMethod(.linear)
                    .lineStyle(.init(lineWidth: 2))
                    .foregroundStyle(isPositive ? Color.green : Color.red)
                }

                ForEach(vm.visibleData) { p in
                    AreaMark(
                        x: .value("Time", p.time),
                        yStart: .value("Min", vm.yMinPadded),
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


            if let last = vm.lastVisiblePoint {
                if range == .sevenDays {
                    if let lastIdx = vm.lastVisibleSevenDayIndex {
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
        .modifier(
            XScaleModifier(
                range: range,
                xDomainDate: vm.xDomainDate,
                xDomainIndex: vm.xDomainIndex
            )
        )
        .chartYScale(domain: vm.yMinPadded ... vm.yMaxPadded)

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
                AxisMarks(values: vm.sevenDayTickIndicesLimited) { value in
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))

                    if let idx = value.as(Int.self),
                       idx >= 0,
                       idx < vm.visibleData.count {
                        let date = vm.visibleData[idx].time
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
                    values: .automatic(desiredCount: vm.xLabelCount)
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
