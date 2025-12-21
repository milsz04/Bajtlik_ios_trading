import Testing
@testable import Bajtlik_ios_trading
import Foundation

@MainActor
struct  StockLineChartViewModelTests  {

    // Test checks if the chart has extra space above maximum price and below the minimum price
    @Test
    func yAxisPaddingIsCorrect() {
        let data = [
            PricePoint(time: Date(), price: 100),
            PricePoint(time: Date().addingTimeInterval(60), price: 110)
        ]

        let vm = StockLineChartViewModel(data: data, range: .oneDay)

        #expect(vm.yMinPadded < 100)
        #expect(vm.yMaxPadded > 110)
    }

    // Test checks that the chart always has data to display, even when only one data point is provided
    @Test
    func visibleDataIsNotEmpty() {
        let data = [
            PricePoint(time: Date(), price: 50)
        ]

        let vm = StockLineChartViewModel(data: data, range: .oneDay)

        #expect(!vm.visibleData.isEmpty)
    }

    // Test checks that data used by the chart is always sorted by time
    @Test
    func visibleDataIsSortedByTime() {
        let t0 = Date()
        let t1 = t0.addingTimeInterval(60)
        let t2 = t0.addingTimeInterval(120)

        // celowo wrzucamy w złej kolejności
        let data = [
            PricePoint(time: t2, price: 3),
            PricePoint(time: t0, price: 1),
            PricePoint(time: t1, price: 2)
        ]

        let vm = StockLineChartViewModel(data: data, range: .oneDay)

        let times = vm.visibleData.map(\.time)
        #expect(times == times.sorted())
    }

    // Test checks if tryBuy returns true and decreases balance when user has enough funds
    @Test
    func tryBuySucceedsAndDecreasesBalance() {
        let sm = StockManager()
        sm.balance = 1000

        let ok = sm.tryBuy(shares: 2, pricePerShare: 100)

        #expect(ok == true)
        #expect(sm.balance == 800)
    }

    // Test checks if tryBuy returns false and does not change balance when user has not enough funds
    @Test
    func tryBuyFailsAndDoesNotChangeBalance() {
        let sm = StockManager()
        sm.balance = 100

        let ok = sm.tryBuy(shares: 2, pricePerShare: 100) // koszt 200

        #expect(ok == false)
        #expect(sm.balance == 100)
    }



    // Test checks if availableCash is computed as balance - reservedCash (and never goes negative)
    @Test
    func availableCashIsBalanceMinusReservedNeverNegative() {
        let sm = StockManager()

        sm.balance = 1000
        sm.reservedCash = 250
        #expect(sm.availableCash == 750)

        sm.balance = 100
        sm.reservedCash = 200
        #expect(sm.availableCash == 0)
    }

        // Test checks that resetAccount restores default balance and clears reserved cash
    @Test
    func resetAccountRestoresDefaultValues() {
        let sm = StockManager()
        sm.balance = 1234
        sm.reservedCash = 567

        sm.resetAccount()

        #expect(sm.balance == 10_000)
        #expect(sm.reservedCash == 0)
    }

    // Test checks that availableSharesToSell never becomes negative
    @Test
    func availableSharesToSellIsNotNegative() {
        let item = StockItem(
            name: "Apple",
            code: "AAPL",
            current: 100,
            change: 0,
            percentChange: 0,
            high: 0,
            low: 0,
            open: 0,
            previousClose: 0,
            sharesOwned: 1,
            avgCost: 100,
            costBasis: 100,
            reservedShares: 5
        )

        #expect(item.availableSharesToSell == 0)
    }

    // Test checks market value and profit/loss calculations
    @Test
    func marketValueAndUnrealizedPLAreCorrect() {
        let item = StockItem(
            name: "Apple",
            code: "AAPL",
            current: 150,
            change: 0,
            percentChange: 0,
            high: 0,
            low: 0,
            open: 0,
            previousClose: 0,
            sharesOwned: 2,
            avgCost: 100,
            costBasis: 200,
            reservedShares: 0
        )

        #expect(item.marketValue == 300)
        #expect(item.unrealizedPL == 100)
        #expect(item.unrealizedPLPercent == 50)
    }

    // Test checks that unrealizedPLPercent returns 0 when costBasis is 0
    @Test
    func unrealizedPLPercentIsZeroWhenCostBasisZero() {
        let item = StockItem(
            name: "Apple",
            code: "AAPL",
            current: 150,
            change: 0,
            percentChange: 0,
            high: 0,
            low: 0,
            open: 0,
            previousClose: 0,
            sharesOwned: 2,
            avgCost: 0,
            costBasis: 0,
            reservedShares: 0
        )

        #expect(item.unrealizedPLPercent == 0)
    }

    // Test checks that filtering returns all items when searchText is empty
    @Test
    func filterReturnsAllWhenSearchIsEmpty() {
        let vm = WatchlistViewModel()
        vm.searchText = ""

        let apple  = WatchlistItem(
            name: "Apple",
            code: "AAPL",
            current: 0,
            change: 0,
            percentChange: 0,
            high: 0,
            low: 0,
            open: 0,
            previousClose: 0
        )
        let microsoft  = WatchlistItem(
            name: "Microsoft",
            code: "MSFT",
            current: 0,
            change: 0,
            percentChange: 0,
            high: 0,
            low: 0,
            open: 0,
            previousClose: 0
        )

        let out = vm.filteredStocks( from: [apple, microsoft]  )
        #expect(out.count == 2)
    }

    // Test checks that filtering is case-insensitive and matches by name or code
    @Test
    func filterIsCaseInsensitiveAndMatchesNameOrCode() {
        let vm = WatchlistViewModel()
        vm.searchText = "ap"

        let apple = WatchlistItem(
            name: "Apple Inc.",
            code: "AAPL",
            current: 0,
            change: 0,
            percentChange: 0,
            high: 0,
            low: 0,
            open: 0,
            previousClose: 0
        )
        let microsoft = WatchlistItem(
            name: "Microsoft",
            code: "MSFT",
            current: 0,
            change: 0,
            percentChange: 0,
            high: 0,
            low: 0,
            open: 0,
            previousClose: 0
        )

        let out = vm.filteredStocks(from: [apple, microsoft])

        #expect(out.count == 1)
        #expect(out.first?.code == "AAPL")
    }
}

