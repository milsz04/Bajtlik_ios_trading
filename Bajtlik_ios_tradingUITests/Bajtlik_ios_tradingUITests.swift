import XCTest

final class BajtlikUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        
        let watchlistHeader = app.staticTexts["Watchlist"]
        XCTAssertTrue(watchlistHeader.waitForExistence(timeout: 5), "App failed to pass splash screen.")
    }

    // MARK: - Navigation Tests
    
    func testTabNavigation() throws {
        let tabBar = app.tabBars.firstMatch
        
        //tap wallet
        tabBar.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.staticTexts["Bajtlik"].exists)
        
        //tap trade
        tabBar.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.staticTexts["Trade"].exists)
        
        //tap settings
        tabBar.buttons.element(boundBy: 3).tap()
        XCTAssertTrue(app.staticTexts["Settings"].exists)
    }

    // MARK: - Watchlist Flow
    
    func testAddStockAndOpenDetails() throws {
        // open the add
        let addButton = app.buttons["watchlistSearchButton"]
        XCTAssertTrue(addButton.exists)
        addButton.tap()
        
        // alert interaction
        let alert = app.alerts["Add Stock Symbol"]
        XCTAssertTrue(alert.exists)
        
        let textField = alert.textFields.firstMatch
        textField.typeText("AAPL")
        alert.buttons["Add"].tap()
        
        // tap the cell after it exists
        let stockCell = app.staticTexts["AAPL"]
        XCTAssertTrue(stockCell.waitForExistence(timeout: 2))
        stockCell.tap()
        
        // verify we are in the detailed stockview with time range buttons
        XCTAssertTrue(app.buttons["1D"].exists)
    }

    // MARK: - Trading Flow
    
    func testMarketBuyExecution() throws {
        app.tabBars.buttons.element(boundBy: 2).tap()

        let picker = app.segmentedControls["tradeTypePicker"]
        
        // tap buy
        picker.buttons["Buy"].tap()
        
        let sharesInput = app.textFields["tradeSharesInput"]
        sharesInput.tap()
        sharesInput.typeText("1")
    
        // leave keyboard
        app.toolbars.buttons["Done"].tap()
        
        // tap trade
        let executeButton = app.buttons["executeTradeButton"]
        XCTAssertTrue(executeButton.exists)
        executeButton.tap()
        
        let resultAlert = app.alerts.firstMatch
        XCTAssertTrue(resultAlert.exists)

        
        let okButton = app.buttons["OK"]
        okButton.tap()
    }

    // MARK: - Settings Flow
    
    func testResetAccountBalance() throws {
        app.tabBars.buttons.element(boundBy: 3).tap()
        
        let resetButton = app.buttons["Reset Available Funds"]
        resetButton.tap()
        
        let confirmAlert = app.alerts["Reset Account"]
        XCTAssertTrue(confirmAlert.exists)
        confirmAlert.buttons["Reset"].tap()
    
        XCTAssertTrue(app.staticTexts["Settings"].exists)
    }
}
