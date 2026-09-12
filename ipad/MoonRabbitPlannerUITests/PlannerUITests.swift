import XCTest

final class PlannerUITests: XCTestCase {
    func testBundledPlannerLoadsInPortraitAndLandscape() {
        let app = XCUIApplication()
        app.launch()
        let webView = app.webViews.firstMatch
        XCTAssertTrue(webView.waitForExistence(timeout: 20), "Bundled planner must render in WKWebView")
        XCTAssertTrue(app.staticTexts["오늘의 목표"].waitForExistence(timeout: 20), "Planner HTML must finish rendering")
        let agents = app.buttons["에이전트"].firstMatch
        XCTAssertTrue(agents.waitForExistence(timeout: 10))
        agents.tap()
        XCTAssertTrue(app.staticTexts["에이전트 작업실"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["주간"].firstMatch.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "이전 주")).firstMatch.waitForExistence(timeout: 10))
        app.buttons["일간"].firstMatch.tap()
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
