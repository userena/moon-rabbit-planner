import XCTest
@testable import MoonRabbit

final class CompanionTests: XCTestCase {
    func testOneWeekPeriodIncludesSevenDaysAcrossMonthBoundary() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2026, month: 9, day: 28))!
        let end = PlannerPeriod.week.end(start: start, calendar: calendar)
        XCTAssertEqual(calendar.dateComponents([.day], from: start, to: end).day, 6)
        XCTAssertEqual(calendar.component(.month, from: end), 10)
        XCTAssertEqual(calendar.component(.day, from: end), 4)
    }
    func testPlannerNameAndPalettePreserveCustomization() throws {
        var appearance = PetAppearance()
        appearance.plannerTitle = "  My studio  "
        appearance.plannerAccent = PetColor(0.2, 0.6, 0.8)
        appearance.updateLegacyPlannerPalette()
        let restored = try JSONDecoder().decode(PetAppearance.self, from: JSONEncoder().encode(appearance))
        XCTAssertEqual(restored.resolvedPlannerTitle(language: .en), "My studio")
        XCTAssertEqual(restored.plannerAccent, PetColor(0.2, 0.6, 0.8))
        appearance.plannerTitle = " \n "
        XCTAssertEqual(appearance.resolvedPlannerTitle(language: .ko), "달토끼 플래너")
        var old = PetAppearance()
        old.plannerBackground = PetColor(0.97, 0.96, 0.92)
        old.plannerAccent = PetColor(0.40, 0.55, 0.46)
        old.updateLegacyPlannerPalette()
        XCTAssertEqual(old.plannerAccent, PetAppearance().plannerAccent)
    }
    func testPlannerRoundTripAndCompletedTasks() throws {
        var plan = DailyPlan()
        plan.entries[DailyPlan.key(for: Date())] = [PlanItem(time: "09:00", title: "Write", done: false), PlanItem(time: "10:00", title: "Read", done: true)]
        let restored = try JSONDecoder().decode(DailyPlan.self, from: JSONEncoder().encode(plan))
        XCTAssertEqual(restored.items().count, 2)
        XCTAssertEqual(restored.todaySummary, "09:00 Write")
        XCTAssertTrue(restored.items(on: Date().addingTimeInterval(86400)).isEmpty)
    }
    func testDateKeyUsesLocalCalendar() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 9 * 3600)!
        let date = ISO8601DateFormatter().date(from: "2026-09-12T16:00:00Z")!
        XCTAssertEqual(DailyPlan.key(for: date, calendar: calendar), "2026-09-13")
    }
    func testLegacyPlannerMigration() throws {
        let data = Data(#"{"entries":{"2026-09-12":[{"time":"09:00","title":"Keep me","done":true}]}}"#.utf8)
        let plan = try JSONDecoder().decode(DailyPlan.self, from: data)
        let item = try XCTUnwrap(plan.entries["2026-09-12"]?.first)
        XCTAssertEqual(item.title, "Keep me")
        XCTAssertTrue(item.done)
        XCTAssertEqual(item.minutes, 60)
        XCTAssertEqual(item.category, "")
        XCTAssertTrue(plan.notes.isEmpty)
        XCTAssertTrue(plan.workSeconds.isEmpty)
    }
    func testDDayUsesCalendarDaysAcrossDST() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 1))!
        let next = calendar.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 0))!
        XCTAssertEqual(DDay.label(target: next, today: today, calendar: calendar), "D−1")
        XCTAssertEqual(DDay.label(target: today.addingTimeInterval(3600), today: today, calendar: calendar), "D-DAY")
        XCTAssertEqual(DDay.label(target: today, today: next, calendar: calendar), "D+1")
    }
    func testPlannerTimeBoundariesAndNotesPersistence() throws {
        let late = PlanItem(time: "23:50", minutes: 60)
        XCTAssertTrue(late.occupies(minute: 1439))
        XCTAssertFalse(late.occupies(minute: 1440))
        XCTAssertFalse(late.occupies(minute: 1429))
        XCTAssertNil(PlanItem(time: "25:00").startMinute)
        XCTAssertFalse(PlanItem(time: "09:00", minutes: -10).occupies(minute: 540))
        var plan = DailyPlan()
        plan.notes["2026-09-12"] = "Remember this"
        plan.workSeconds["2026-09-12"] = 3660
        let restored = try JSONDecoder().decode(DailyPlan.self, from: JSONEncoder().encode(plan))
        XCTAssertEqual(restored.notes, plan.notes)
        XCTAssertEqual(restored.workSeconds, plan.workSeconds)
    }
    func testAppearancePersistenceAndCustomCountdown() throws {
        var appearance = PetAppearance()
        appearance.plannerTitle = "My studio"
        appearance.ddayPrefix = "마감"
        appearance.bubbleBackground = PetColor(0.1, 0.2, 0.3)
        let restored = try JSONDecoder().decode(PetAppearance.self, from: JSONEncoder().encode(appearance))
        XCTAssertEqual(restored, appearance)
        let today = Date()
        XCTAssertEqual(restored.dayLabel(target: today, today: today), "마감 0")
        let future = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        XCTAssertEqual(restored.dayLabel(target: future, today: today), "마감 −7")
    }
    func testTenMinutePlanningAndLegacyOverlap() {
        XCTAssertEqual(PlanItem.tenMinuteDuration(0), 10)
        XCTAssertEqual(PlanItem.tenMinuteDuration(61), 60)
        XCTAssertEqual(PlanItem.tenMinuteDuration(70), 70)
        XCTAssertEqual(PlanItem.tenMinuteDuration(2000), 1440)
        let legacy = PlanItem(time: "09:05", minutes: 10)
        XCTAssertTrue(legacy.overlapsTenMinuteBlock(start: 540))
        XCTAssertTrue(legacy.overlapsTenMinuteBlock(start: 550))
        XCTAssertFalse(legacy.overlapsTenMinuteBlock(start: 560))
    }
    func testScrollableTimeOptions() {
        XCTAssertEqual(PlanningTimeOptions.starts(step: 10).count, 144)
        XCTAssertEqual(PlanningTimeOptions.starts(step: 30).count, 48)
        XCTAssertEqual(PlanningTimeOptions.starts(step: 30).last, 1410)
        XCTAssertEqual(PlanningTimeOptions.durations(step: 30).first, 30)
        XCTAssertEqual(PlanningTimeOptions.durations(step: 10).last, 1440)
        XCTAssertTrue(PlanningTimeOptions.durations(step: 30).allSatisfy { $0 % 30 == 0 })
        XCTAssertEqual(PlanningTimeOptions.clock(1410), "23:30")
        XCTAssertEqual(PlanningTimeOptions.starts(step: 0).count, 144)
    }
    @MainActor func testLiveKoreanNeighborhoodWeather() async throws {
        guard ProcessInfo.processInfo.environment["MOONRABBIT_LIVE_WEATHER"] == "1" else {
            throw XCTSkip("Enable explicitly for live network verification")
        }
        for query in ["서울 연남동", "부산 우동", "제주 애월읍"] {
            let matches = try await WeatherService.search(query: query, language: .ko)
            let place = try XCTUnwrap(matches.first, query)
            print("LIVE PLACE: \(query) → \(place.label) (\(place.latitude), \(place.longitude))")
            XCTAssertTrue((32...39).contains(place.latitude))
            XCTAssertTrue((124...132).contains(place.longitude))
            let weather = try await WeatherService.current(place: place)
            XCTAssertFalse(weather.time.isEmpty)
            print("LIVE WEATHER: \(weather.time) \(weather.temperature_2m)°C")
        }
    }
    func testTaskColorSurvivesSaving() throws {
        let task = PlanItem(time: "09:30", title: "Coffee", color: PetColor(0.4, 0.2, 0.8))
        let restored = try JSONDecoder().decode(PlanItem.self, from: JSONEncoder().encode(task))
        XCTAssertEqual(restored.color, task.color)
    }
    func testThirtyMinuteTimelineOverlap() {
        let task = PlanItem(time: "09:20", minutes: 30)
        XCTAssertTrue(task.overlapsBlock(start: 540, length: 30))
        XCTAssertTrue(task.overlapsBlock(start: 570, length: 30))
        XCTAssertFalse(task.overlapsBlock(start: 600, length: 30))
    }
    func testRolePagesRemainSeparateAndSurviveSaving() throws {
        var plan = DailyPlan()
        plan.rolePages["2026-09-12:developer", default: RolePage()].notes["next"] = "Fix login"
        plan.rolePages["2026-09-12:designer", default: RolePage()].checked["contrast"] = true
        let restored = try JSONDecoder().decode(DailyPlan.self, from: JSONEncoder().encode(plan))
        XCTAssertEqual(restored.rolePages["2026-09-12:developer"]?.notes["next"], "Fix login")
        XCTAssertNil(restored.rolePages["2026-09-13:developer"])
        XCTAssertNil(restored.rolePages["2026-09-12:designer"]?.notes["next"])
    }
    func testStudyTotalsUseCheckedPlannedDurations() {
        let summary = StudyTotal.summarize([PlanItem(title: "Review", done: true, category: "Math", minutes: 30), PlanItem(title: "Practice", category: "Math", minutes: 60)], fallback: "Other")
        XCTAssertEqual(summary, [StudyTotal(subject: "Math", planned: 90, completed: 30)])
    }
    func testAutonomousDestinationMakesMeaningfulTrips() {
        XCTAssertEqual(WanderDestination.choose(current: 500, lower: 0, upper: 1000, fraction: 0.51), 1000)
        XCTAssertEqual(WanderDestination.choose(current: 500, lower: 0, upper: 1000, fraction: 0.1), 100)
        XCTAssertEqual(WanderDestination.choose(current: 5, lower: 10, upper: 10, fraction: 0.5), 10)
    }
    func testModeMigrationAndIsolation() throws {
        var plan = DailyPlan()
        plan.legacyRole = WorkRole.designer.rawValue
        plan.entries["2026-09-12"] = [PlanItem(title: "Keep old work")]
        XCTAssertEqual(plan.modeItems(day: "2026-09-12", role: .designer).count, 1)
        XCTAssertTrue(plan.modeItems(day: "2026-09-12", role: .developer).isEmpty)
        plan.setModeItems([PlanItem(title: "Build")], day: "2026-09-12", role: .developer)
        let restored = try JSONDecoder().decode(DailyPlan.self, from: JSONEncoder().encode(plan))
        XCTAssertEqual(restored.modeItems(day: "2026-09-12", role: .designer).first?.title, "Keep old work")
        XCTAssertEqual(restored.modeItems(day: "2026-09-12", role: .developer).first?.title, "Build")
        XCTAssertEqual(WorkRole.allCases.count, 7)
    }
    func testPeriodsUseCalendarDaysAndMonthEnds() {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = c.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        XCTAssertEqual(c.dateComponents([.day], from: start, to: PlannerPeriod.days100.end(start: start, calendar: c)).day, 99)
        XCTAssertEqual(c.dateComponents([.day], from: start, to: PlannerPeriod.days200.end(start: start, calendar: c)).day, 199)
        XCTAssertEqual(DailyPlan.key(for: PlannerPeriod.month.end(start: start, calendar: c), calendar: c), "2026-01-31")
        XCTAssertEqual(DailyPlan.key(for: PlannerPeriod.year.end(start: start, calendar: c), calendar: c), "2026-12-31")
    }
    func testAlarmsFireOnceAndRepeatAfterSleep() {
        let now = Date()
        var once = RabbitAlarm(title: "Review", date: now.addingTimeInterval(-5))
        XCTAssertTrue(once.consumeIfDue(now: now))
        XCTAssertFalse(once.consumeIfDue(now: now.addingTimeInterval(1)))
        var daily = RabbitAlarm(title: "Stretch", date: now.addingTimeInterval(-172800), daily: true)
        XCTAssertTrue(daily.consumeIfDue(now: now))
        XCTAssertGreaterThan(daily.date, now)
        XCTAssertFalse(daily.consumeIfDue(now: now.addingTimeInterval(1)))
    }
    func testWalkingFramesFollowDistanceNotElapsedTime() {
        XCTAssertEqual(WalkCycle.frame(distance: 0), 0)
        XCTAssertEqual(WalkCycle.frame(distance: 16), 1)
        XCTAssertEqual(WalkCycle.frame(distance: 32), 2)
        XCTAssertEqual(WalkCycle.frame(distance: 48), 3)
        XCTAssertEqual(WalkCycle.frame(distance: 64), 0)
        XCTAssertEqual(WalkCycle.frame(distance: .infinity), 0)
    }
    func testMonthlyRecordsPersistAndRemainIsolated() throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let september = calendar.date(from: DateComponents(year: 2026, month: 9, day: 12))!
        let october = calendar.date(byAdding: .month, value: 1, to: september)!
        let key = MonthlyRecord.key(date: september, role: .developer, calendar: calendar)
        var plan = DailyPlan()
        plan.monthlyRecords[key] = MonthlyRecord(goal: "Ship", note: "Review", tasks: [PlanItem(title: "Release", done: true)])
        plan.setModeItems([PlanItem(title: "Daily")], day: "2026-09-12", role: .developer)
        let restored = try JSONDecoder().decode(DailyPlan.self, from: JSONEncoder().encode(plan))
        XCTAssertEqual(restored.monthlyRecords[key]?.goal, "Ship")
        XCTAssertEqual(restored.monthlyRecords[key]?.note, "Review")
        XCTAssertEqual(restored.monthlyRecords[key]?.tasks.first?.done, true)
        XCTAssertNil(restored.monthlyRecords[MonthlyRecord.key(date: october, role: .developer, calendar: calendar)])
        XCTAssertNil(restored.monthlyRecords[MonthlyRecord.key(date: september, role: .student, calendar: calendar)])
        XCTAssertEqual(restored.modeItems(day: "2026-09-12", role: .developer).first?.title, "Daily")
        let legacy = try JSONDecoder().decode(DailyPlan.self, from: Data(#"{"entries":{}}"#.utf8))
        XCTAssertTrue(legacy.monthlyRecords.isEmpty)
    }
    func testWeatherURLSafelyEncodesCity() {
        let url = WeatherService.searchURL(query: "서울 & London", language: .ko)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        XCTAssertEqual(items.first { $0.name == "name" }?.value, "서울 & London")
        XCTAssertEqual(url.host, "geocoding-api.open-meteo.com")
    }
    func testWeatherResponseAndConditions() throws {
        let data = Data(#"{"time":"2026-09-12T14:00","temperature_2m":22.5,"apparent_temperature":23.1,"weather_code":61,"wind_speed_10m":8.2}"#.utf8)
        let weather = try JSONDecoder().decode(CurrentWeather.self, from: data)
        XCTAssertEqual(weather.descriptionKey, "비")
        XCTAssertEqual(weather.temperature_2m, 22.5)
    }
}
