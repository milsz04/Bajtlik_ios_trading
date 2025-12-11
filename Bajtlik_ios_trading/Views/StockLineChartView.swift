import SwiftUI
import Charts
import Combine

struct StockLineChart: View {
    @StateObject private var vm: StockLineChartViewModel
    let isPositive: Bool
    let range: ChartTimeRange

    init(data: [PricePoint], isPositive: Bool, range: ChartTimeRange) {
        _vm = StateObject(wrappedValue: StockLineChartViewModel(data: data, range: range))
        self.isPositive = isPositive
        self.range = range
    }

    var body: some View {
        Chart {
            if range == .sevenDays {
                ForEach(vm.sevenDayIndexed, id: \.point.id) { item in
                    LineMark(
                        x: .value("Index", item.index),
                        y: .value("Price", item.point.price)
                    )
                    .foregroundStyle(isPositive ? Color.green : Color.red)

                    AreaMark(
                        x: .value("Index", item.index),
                        yStart: .value("Min", vm.yMinPadded),
                        yEnd: .value("Price", item.point.price)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [(isPositive ? Color.green : Color.red).opacity(0.3), Color.clear],
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
                    .foregroundStyle(isPositive ? Color.green : Color.red)
                }
            }
        }
        .modifier(XScaleModifier(range: range,
                                 xDomainDate: vm.xDomainDate,
                                 xDomainIndex: vm.xDomainIndex))
        .chartYScale(domain: vm.yMinPadded...vm.yMaxPadded)
        .frame(height: 260)
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
