import XCTest

final class PlannerUITests: XCTestCase {
    func testBundledPlannerLoadsInPortraitAndLandscape() {
        let app = XCUIApplication()
        app.launch()
        let webView = app.webViews.firstMatch
        XCTAssertTrue(webView.waitForExistence(timeout: 20), "Bundled planner must render in WKWebView")
        XCTAssertTrue(app.staticTexts["오늘의 목표"].waitForExistence(timeout: 20), "Planner HTML must finish rendering")
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(webView.exists)
        let landscape = XCTAttachment(screenshot: app.screenshot())
        landscape.name = "iPad planner landscape"
        landscape.lifetime = .keepAlways
        add(landscape)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(webView.exists)
        let portrait = XCTAttachment(screenshot: app.screenshot())
        portrait.name = "iPad planner portrait"
        portrait.lifetime = .keepAlways
        add(portrait)
    }
}
