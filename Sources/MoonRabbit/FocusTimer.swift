import Foundation

enum TimerMode: String, CaseIterable { case stopwatch, countdown }

struct FocusTimer {
    private(set) var remaining: TimeInterval
    init(seconds: TimeInterval) { remaining = WorkClock.safeSeconds(seconds) }
    /// Returns true once, at the transition to zero.
    mutating func advance(by seconds: TimeInterval) -> Bool {
        guard remaining > 0, seconds.isFinite else { return false }
        remaining = max(0, remaining - max(0, seconds))
        return remaining == 0
    }
    var display: String {
        let seconds = Int(ceil(remaining))
        if seconds >= 3600 { return String(format: "%02d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60) }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
