import XCTest
@testable import MoonRabbit
final class PersonalAPITests: XCTestCase {
    func testRequestsAreBoundedAndFixedHost() throws {
        for provider in PersonalAPI.providers {
            let request = try PersonalAPI.request(provider: provider, model: "test-model", prompt: "hello", key: "fixture-not-real")
            XCTAssertEqual(request.url?.scheme, "https")
            XCTAssertFalse(request.url!.absoluteString.contains("fixture"))
            XCTAssertEqual(request.httpMethod, "POST")
        }
        XCTAssertThrowsError(try PersonalAPI.request(provider: "Gemini", model: "../other", prompt: "hello", key: "fixture"))
        XCTAssertThrowsError(try PersonalAPI.request(provider: "unknown", model: "model", prompt: "hello", key: "fixture"))
        let data = Data("{\"output\":[{\"content\":[{\"text\":\"response\"}]}]}".utf8)
        XCTAssertEqual(try PersonalAPI.response(data, provider: "OpenAI"), "response")
    }
    func testOvernightRoutineAndInclusivePeriod() {
        var routine = RoutineRecord(); routine.bedtime = 1380; routine.wake = 420
        XCTAssertEqual(routine.sleepMinutes, 480)
        let day = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 2, to: day)!
        let period = CalendarPeriod(name: "Exam", start: day, end: end, color: PetColor(.pink))
        XCTAssertTrue(period.includes(day)); XCTAssertTrue(period.includes(end))
        XCTAssertFalse(period.includes(Calendar.current.date(byAdding: .day, value: 3, to: day)!))
    }
}
