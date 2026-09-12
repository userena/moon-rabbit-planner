import XCTest
@testable import MoonRabbit
final class WorkClockTests: XCTestCase {
    func testPausedTimeExcluded() {
        var c = WorkClock(); c.start(now: 100); c.pause(now: 160)
        XCTAssertNil(c.tick(now: 1000)); XCTAssertEqual(c.elapsed, 60)
        c.start(now: 1000); c.tick(now: 1030); XCTAssertEqual(c.elapsed, 90)
    }
    func testHourlyAnnouncementExactlyOnce() {
        var c = WorkClock(); c.start(now: 0)
        XCTAssertNil(c.tick(now: 3599)); XCTAssertEqual(c.tick(now: 3600), 1)
        XCTAssertNil(c.tick(now: 3601)); XCTAssertEqual(c.tick(now: 7200), 2)
    }
    func testRestorePausedAndReset() {
        var c = WorkClock(elapsed: 3661)
        XCTAssertFalse(c.isRunning); XCTAssertEqual(c.display, "01:01:01")
        c.start(now: 1); XCTAssertNil(c.tick(now: 2))
        c.reset(); XCTAssertEqual(c.elapsed, 0); XCTAssertFalse(c.isRunning)
    }
}

final class PetBehaviorTests: XCTestCase {
    func testParkedPetNeverMoves() {
        var motion = WanderMotion()
        _ = motion.advance(x: 100, target: 500, lower: 0, upper: 600, dt: 0.03, enabled: true)
        XCTAssertEqual(motion.advance(x: 100, target: 500, lower: 0, upper: 600, dt: 0.03, enabled: false), 100)
        XCTAssertEqual(motion.velocity, 0)
    }
    func testWalkArrivesWithoutOvershooting() {
        var motion = WanderMotion(); var x = 0.0
        for _ in 0..<1500 {
            x = motion.advance(x: x, target: 300, lower: 0, upper: 400, dt: 1.0 / 30, enabled: true)
            XCTAssertGreaterThanOrEqual(x, 0); XCTAssertLessThanOrEqual(x, 300)
        }
        XCTAssertEqual(x, 300, accuracy: 0.5)
    }
    func testOffscreenTargetClamped() {
        var motion = WanderMotion(); var x = 50.0
        for _ in 0..<1500 { x = motion.advance(x: x, target: -100, lower: 0, upper: 100, dt: 0.033, enabled: true) }
        XCTAssertEqual(x, 0, accuracy: 0.5)
    }
    func testDialogueDoesNotRepeatImmediately() {
        var dialogue = PetDialogue()
        for activity in PetActivity.allCases {
            var last = dialogue.next(for: activity)
            for _ in 0..<30 { let next = dialogue.next(for: activity); XCTAssertNotEqual(last, next); last = next }
        }
    }
}

import AppKit
final class ArtworkTests: XCTestCase {
    func testEveryPoseHasTransparentBackground() throws {
        for name in ["rabbit", "smile", "dance", "snack", "walkA", "walkB", "blink", "danceB", "snackB", "stretch", "stretchB", "flower", "flowerB", "coffee", "coffeeB", "sideWalkA", "sideWalkB", "walkCycle0", "walkCycle1", "walkCycle2", "walkCycle3", "turnThreeQuarter", "workLaptop0", "workLaptop1", "workDesign0", "workDesign1", "workStudy0", "workStudy1", "workPlan0", "workPlan1"] {
            let url = try XCTUnwrap(PetArtwork.bundle.url(forResource: name, withExtension: "png"))
            let bitmap = try XCTUnwrap(NSBitmapImageRep(data: Data(contentsOf: url)))
            for (x, y) in [(0, 0), (bitmap.pixelsWide - 1, 0), (0, bitmap.pixelsHigh - 1), (bitmap.pixelsWide - 1, bitmap.pixelsHigh - 1)] {
                XCTAssertEqual(bitmap.colorAt(x: x, y: y)?.alphaComponent, 0, "Opaque background in \(name)")
            }
            XCTAssertGreaterThan(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh / 2)!.alphaComponent, 0.9)
        }
    }
}

final class FocusTimerTests: XCTestCase {
    func testCountdownCompletesOnlyOnce() {
        var timer = FocusTimer(seconds: 60)
        XCTAssertFalse(timer.advance(by: 59)); XCTAssertEqual(timer.display, "00:01")
        XCTAssertTrue(timer.advance(by: 2)); XCTAssertEqual(timer.remaining, 0)
        XCTAssertFalse(timer.advance(by: 1))
    }
    func testPauseExcludesTimeFromCountdown() {
        var clock = WorkClock(); var timer = FocusTimer(seconds: 1500)
        clock.start(now: 0); clock.pause(now: 60)
        timer.advance(by: clock.elapsed)
        let before = clock.elapsed
        clock.tick(now: 3600); timer.advance(by: clock.elapsed - before)
        XCTAssertEqual(timer.display, "24:00")
    }
    func testRestoredTimeAndInvalidDeltas() {
        var timer = FocusTimer(seconds: 90)
        XCTAssertFalse(timer.advance(by: -100)); XCTAssertEqual(timer.display, "01:30")
        XCTAssertEqual(FocusTimer(seconds: -1).remaining, 0)
    }
}

final class LocalizationTests: XCTestCase {
    func testAllActivitiesHaveEnglishDialogue() {
        for activity in PetActivity.allCases {
            XCTAssertEqual(PetDialogue.lines[activity]?.count, PetDialogue.english[activity]?.count)
            XCTAssertFalse(PetDialogue.english[activity, default: []].isEmpty)
        }
    }
    func testEnglishLabelsDoNotContainKorean() {
        for (_, value) in PetStrings.english {
            XCTAssertFalse(value.unicodeScalars.contains { (0xAC00...0xD7AF).contains($0.value) })
        }
    }
}
