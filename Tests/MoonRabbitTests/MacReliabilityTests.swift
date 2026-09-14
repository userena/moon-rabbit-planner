import XCTest
@testable import MoonRabbit

final class MacReliabilityTests: XCTestCase {
    func testInvalidTimerValuesRemainDisplayable() {
        for value in [Double.infinity, -.infinity, .nan, .greatestFiniteMagnitude, -1] {
            let clock = WorkClock(elapsed: value)
            let timer = FocusTimer(seconds: value)
            XCTAssertTrue(clock.elapsed.isFinite)
            XCTAssertTrue(timer.remaining.isFinite)
            XCTAssertFalse(clock.display.isEmpty)
            XCTAssertFalse(timer.display.isEmpty)
        }
        var clock = WorkClock(elapsed: 60)
        clock.start(now: 0)
        XCTAssertNil(clock.tick(now: .nan))
        XCTAssertEqual(clock.elapsed, 60)
        clock.tick(now: 10)
        XCTAssertEqual(clock.elapsed, 70)
        var timer = FocusTimer(seconds: 60)
        XCTAssertFalse(timer.advance(by: .nan))
        XCTAssertFalse(timer.advance(by: .infinity))
        XCTAssertEqual(timer.remaining, 60)
    }
    func testIncompletePalettePreservesNotesAndFillsMissingColors() throws {
        for json in [#"{"notes":{"brief":"Keep this"},"colors":[]}"#, #"{"notes":{"brief":"Keep this"}}"#] {
            let page = try JSONDecoder().decode(RolePage.self, from: Data(json.utf8))
            XCTAssertEqual(page.colors.count, 3)
            XCTAssertEqual(page.notes["brief"], "Keep this")
            let restored = try JSONDecoder().decode(RolePage.self, from: JSONEncoder().encode(page))
            XCTAssertEqual(restored.colors.count, 3)
        }
    }
    func testExtremeStoredTimesDoNotOverflow() {
        XCTAssertEqual(PlanningTimeOptions.nearest(to: .min, in: [0,10,20]), 0)
        XCTAssertEqual(PlanningTimeOptions.nearest(to: .max, in: [0,10,20]), 20)
        XCTAssertEqual(PlanningTimeOptions.nearest(to: 18, in: [0,10,20]), 20)
        XCTAssertNil(PlanningTimeOptions.nearest(to: 10, in: []))
        var routine = RoutineRecord()
        routine.bedtime = .min; routine.wake = .max
        XCTAssertTrue((0..<1440).contains(routine.sleepMinutes))
        routine.bedtime = 23 * 60; routine.wake = 7 * 60
        XCTAssertEqual(routine.sleepMinutes, 480)
    }
    func testWeatherFallbackAfterPrimaryFailureAndEmptyResults() async throws {
        let place = WeatherPlace(id: 1, name: "서울", latitude: 37.5, longitude: 127, admin1: nil, country: nil)
        for fails in [true, false] {
            var fallbackCount = 0
            let result = try await WeatherService.searchWithFallback(primary: {
                if fails { throw URLError(.timedOut) }; return []
            }, fallback: { fallbackCount += 1; return [place] })
            XCTAssertEqual(result.first?.name, "서울")
            XCTAssertEqual(fallbackCount, 1)
        }
        let result = try await WeatherService.searchWithFallback(primary: { [place] }, fallback: { XCTFail("Unnecessary fallback"); return [] })
        XCTAssertEqual(result.count, 1)
    }
    func testWeatherCancellationNeverStartsFallback() async {
        do {
            _ = try await WeatherService.searchWithFallback(primary: { throw CancellationError() }, fallback: { XCTFail("Cancelled request must stop"); return [] })
            XCTFail("Expected cancellation")
        } catch { XCTAssertTrue(error is CancellationError) }
    }
    func testWeatherReportsFailureWhenBothServicesFail() async {
        do {
            _ = try await WeatherService.searchWithFallback(primary: { throw URLError(.timedOut) }, fallback: { throw URLError(.notConnectedToInternet) })
            XCTFail("Expected failure")
        } catch { XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet) }
    }
}
