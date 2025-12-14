import SwiftUI

struct StockCardBajtlik: View {
    let item: StockItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
                Text(item.code)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("Shares: \(item.sharesOwned, specifier: "%.2f")")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.secondary)

                Text("Value: $\(item.marketValue, specifier: "%.2f")")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.secondary)

                let pl = item.unrealizedPL
                let plPct = item.unrealizedPLPercent
                Text("P/L: \(pl >= 0 ? "+" : "")$\(pl, specifier: "%.2f") (\(plPct >= 0 ? "+" : "")\(plPct, specifier: "%.2f")%)")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(pl >= 0 ? .green : .red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray4))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        )
    }
}
