import XCTest

final class BajtlikLaunchTests: XCTestCase {

    func testAppLaunchAndTransition() throws {
        let app = XCUIApplication()
        
        // 1. Launch the application
        app.launch()

        // 2. Verify we see the Splash Screen content first
        // Your HomeView shows a "Welcome!" text
        let welcomeText = app.staticTexts["Welcome!"]
        XCTAssertTrue(welcomeText.exists, "The splash screen Welcome message should be visible on launch.")

        // 3. Wait for the app to transition to the main Watchlist screen
        // We use a 5-second timeout because your code has a 1.5s + 1.0s delay logic
        let watchlistHeader = app.staticTexts["Watchlist"]
        let exists = watchlistHeader.waitForExistence(timeout: 5)

        // 4. Final Assertion
        XCTAssertTrue(exists, "The app failed to transition from the splash screen to the Watchlist view.")
    }
}
