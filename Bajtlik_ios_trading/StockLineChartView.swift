import SwiftUI

import Charts



struct PricePoint: Identifiable {

    let id = UUID()

    let time: Date

    let price: Double

}



struct StockLineChart: View {

    let data: [PricePoint]

    let isPositive: Bool

    

    private var xStart: Date {

        Calendar.current.startOfDay(for: data.first?.time ?? Date())

    }

    private var xEnd: Date {

        Calendar.current.date(byAdding: .hour, value: 24, to: xStart) ?? xStart

    }

    

    private var yMinPadded: Double {

        let minV = data.map(\.price).min() ?? 0

        let maxV = data.map(\.price).max() ?? 1

        let pad = max((maxV - minV) * 0.10, 0.05)

        return minV - pad

    }

    private var yMaxPadded: Double {

        let minV = data.map(\.price).min() ?? 0

        let maxV = data.map(\.price).max() ?? 1

        let pad = max((maxV - minV) * 0.10, 0.05)

        return maxV + pad

    }

    

    var body: some View {

        Chart {

            ForEach(data) { p in

                LineMark(

                    x: .value("Time", p.time),

                    y: .value("Price", p.price)

                )

                .lineStyle(.init(lineWidth: 2))

                .foregroundStyle(isPositive ? Color.green : Color.red)

            }

            

            ForEach(data) { p in

                AreaMark(

                    x: .value("Time", p.time),

                    yStart: .value("Min", yMinPadded),

                    yEnd: .value("Price", p.price)

                )

                .interpolationMethod(.catmullRom)

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

            

            if let last = data.last {

                PointMark(

                    x: .value("Time", last.time),

                    y: .value("Price", last.price)

                )

                .symbolSize(50)

                .foregroundStyle(isPositive ? Color.green : Color.red)

                

                RuleMark(y: .value("Last", last.price))

                    .lineStyle(.init(lineWidth: 1, dash: [4, 4]))

                    .foregroundStyle((isPositive ? Color.green : Color.red).opacity(0.4))

            }

        }

        .chartXScale(domain: xStart ... xEnd)

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

            AxisMarks(position: .bottom) { value in

                AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))

                if let date = value.as(Date.self) {

                    AxisValueLabel {

                        Text(DateFormatter.hhmm.string(from: date))

                            .font(.caption2)

                            .foregroundStyle(.gray)

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

        .frame(height: 220)

        .padding(.vertical, 8)

    }

}



private extension DateFormatter {

    static let hhmm: DateFormatter = {

        let f = DateFormatter()

        f.dateFormat = "HH:mm"

        return f

    }()

}
