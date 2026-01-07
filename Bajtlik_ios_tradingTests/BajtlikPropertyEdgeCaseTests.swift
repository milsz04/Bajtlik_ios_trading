import XCTest
@testable import Bajtlik_ios_trading

@MainActor
final class BajtlikPropertyEdgeCaseTests: XCTestCase {


    private func makeStockItem(
        sharesOwned: Double,
        reservedShares: Double,
        current: Double = 100,
        avgCost: Double = 100,
        costBasis: Double? = nil
    ) -> StockItem {
        StockItem(
            name: "TestCo",
            code: "TST",
            current: current,
            change: 0,
            percentChange: 0,
            high: 0,
            low: 0,
            open: 0,
            previousClose: 0,
            sharesOwned: sharesOwned,
            avgCost: avgCost,
            costBasis: costBasis ?? (sharesOwned * avgCost),
            reservedShares: reservedShares
        )
    }


    func testAvailableSharesToSellNeverNegative() {
        for sharesOwned in stride(from: 0.0, through: 5.0, by: 0.25) {
            for reserved in stride(from: 0.0, through: 10.0, by: 0.25) {
                let item = makeStockItem(sharesOwned: sharesOwned, reservedShares: reserved)
                XCTAssertGreaterThanOrEqual(
                    item.availableSharesToSell,
                    0,
                    "availableSharesToSell became negative for sharesOwned=\(sharesOwned), reserved=\(reserved)"
                )
            }
        }
    }

    func testMarketValueAndUnrealizedPLArenotNaNOrInfiniteForValidInputs() {
        let prices: [Double] = [0.01, 1, 10, 100, 9999.99]
        let shares: [Double] = [0, 0.01, 1, 10, 1000]

        for p in prices {
            for s in shares {
                let item = makeStockItem(sharesOwned: s, reservedShares: 0, current: p, avgCost: p)
                XCTAssertFalse(item.marketValue.isNaN)
                XCTAssertFalse(item.marketValue.isInfinite)

                XCTAssertFalse(item.unrealizedPL.isNaN)
                XCTAssertFalse(item.unrealizedPL.isInfinite)

                XCTAssertFalse(item.unrealizedPLPercent.isNaN)
                XCTAssertFalse(item.unrealizedPLPercent.isInfinite)
            }
        }
    }

    func testUnrealizedPLPercentIsZeroWhenCostBasisIsZero() {
        let item = makeStockItem(sharesOwned: 10, reservedShares: 0, current: 100, avgCost: 0, costBasis: 0)
        XCTAssertEqual(item.unrealizedPLPercent, 0, accuracy: 0.000001)
    }


 
}

