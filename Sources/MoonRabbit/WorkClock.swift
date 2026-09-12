import Foundation

/// Counts only explicitly running, awake time. Relaunch always begins paused.
struct WorkClock {
    private(set) var elapsed: TimeInterval
    private(set) var isRunning = false
    private var lastTick: TimeInterval?
    private(set) var announcedHour: Int

    init(elapsed: TimeInterval = 0) {
        self.elapsed = max(0, elapsed)
        self.announcedHour = Int(max(0, elapsed) / 3600)
    }
    mutating func start(now: TimeInterval) { isRunning = true; lastTick = now }
    @discardableResult mutating func tick(now: TimeInterval) -> Int? {
        guard isRunning, let previous = lastTick else { return nil }
        elapsed += max(0, now - previous)
        lastTick = now
        let hour = Int(elapsed / 3600)
        if hour > announcedHour { announcedHour = hour; return hour }
        return nil
    }
    mutating func pause(now: TimeInterval) { tick(now: now); isRunning = false; lastTick = nil }
    mutating func reset() { self = WorkClock() }
    var display: String {
        let seconds = Int(elapsed)
        return String(format: "%02d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
    }
    var description: String { "\(Int(elapsed) / 3600)시간 \(Int(elapsed) / 60 % 60)분" }
}
