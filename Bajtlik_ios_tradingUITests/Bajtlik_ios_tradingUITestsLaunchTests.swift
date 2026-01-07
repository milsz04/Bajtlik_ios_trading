import XCTest

final class BajtlikLaunchTests: XCTestCase {

    func testAppLaunchAndTransition() throws {
        let app = XCUIApplication()
        
        app.launch()
        
        let welcomeText = app.staticTexts["Welcome!"]
        XCTAssertTrue(welcomeText.exists, "The splash screen Welcome message should be visible on launch.")

        let watchlistHeader = app.staticTexts["Watchlist"]
        let exists = watchlistHeader.waitForExistence(timeout: 5)

        XCTAssertTrue(exists, "The app failed to transition from the splash screen to the Watchlist view.")
    }
}
