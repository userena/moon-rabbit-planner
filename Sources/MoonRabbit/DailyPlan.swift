import Foundation

struct PlanItem: Codable, Identifiable {
    var id = UUID()
    var time = ""
    var title = ""
    var done = false
    var category = ""
    var minutes = 60
    var color: PetColor? = nil
    var owner = ""
    var priority = "normal"
    enum CodingKeys: String, CodingKey { case id, time, title, done, category, minutes, color, owner, priority }
    init(id: UUID = UUID(), time: String = "", title: String = "", done: Bool = false, category: String = "", minutes: Int = 60, color: PetColor? = nil) {
        self.id = id; self.time = time; self.title = title; self.done = done; self.category = category; self.minutes = minutes; self.color = color
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        time = try c.decodeIfPresent(String.self, forKey: .time) ?? ""
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        done = try c.decodeIfPresent(Bool.self, forKey: .done) ?? false
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? ""
        minutes = try c.decodeIfPresent(Int.self, forKey: .minutes) ?? 60
        color = try c.decodeIfPresent(PetColor.self, forKey: .color)
        owner = try c.decodeIfPresent(String.self, forKey: .owner) ?? ""
        priority = try c.decodeIfPresent(String.self, forKey: .priority) ?? "normal"
    }
    var priorityRank: Int { priority == "high" ? 0 : priority == "low" ? 2 : 1 }
    var priorityLabel: String { priority == "high" ? "높음" : priority == "low" ? "낮음" : "보통" }
    var startMinute: Int? {
        let parts = time.trimmingCharacters(in: .whitespaces).split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]), (0..<24).contains(h), (0..<60).contains(m) else { return nil }
        return h * 60 + m
    }
    static func tenMinuteDuration(_ minutes: Int) -> Int {
        let bounded = min(1440, max(10, minutes))
        return ((bounded + 5) / 10) * 10
    }
    func overlapsTenMinuteBlock(start: Int) -> Bool { overlapsBlock(start: start, length: 10) }
    func overlapsBlock(start: Int, length: Int) -> Bool {
        guard let beginning = startMinute, minutes > 0 else { return false }
        return beginning < start + length && min(1440, beginning + min(1440, minutes)) > start
    }
    func occupies(minute: Int) -> Bool {
        guard let start = startMinute else { return false }
        return minute >= start && minute < min(1440, start + min(1440, max(0, minutes)))
    }
}
struct DailyPlan: Codable {
    var entries: [String: [PlanItem]] = [:]
    var notes: [String: String] = [:]
    var workSeconds: [String: Double] = [:]
    var rolePages: [String: RolePage] = [:]
    var modeEntries: [String: [PlanItem]] = [:]
    var legacyRole: String? = nil
    var monthlyRecords: [String: MonthlyRecord] = [:]
    enum CodingKeys: String, CodingKey { case entries, notes, workSeconds, rolePages, modeEntries, legacyRole, monthlyRecords }
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        entries = try c.decodeIfPresent([String: [PlanItem]].self, forKey: .entries) ?? [:]
        notes = try c.decodeIfPresent([String: String].self, forKey: .notes) ?? [:]
        workSeconds = try c.decodeIfPresent([String: Double].self, forKey: .workSeconds) ?? [:]
        rolePages = try c.decodeIfPresent([String: RolePage].self, forKey: .rolePages) ?? [:]
        modeEntries = try c.decodeIfPresent([String: [PlanItem]].self, forKey: .modeEntries) ?? [:]
        legacyRole = try c.decodeIfPresent(String.self, forKey: .legacyRole)
        monthlyRecords = try c.decodeIfPresent([String: MonthlyRecord].self, forKey: .monthlyRecords) ?? [:]
    }
    func modeItems(day: String, role: WorkRole) -> [PlanItem] {
        if let saved = modeEntries[day + ":" + role.rawValue] { return saved }
        return role.rawValue == (legacyRole ?? WorkRole.developer.rawValue) ? entries[day, default: []] : []
    }
    mutating func setModeItems(_ items: [PlanItem], day: String, role: WorkRole) {
        modeEntries[day + ":" + role.rawValue] = items
    }
    func modeSummary(day: String, role: WorkRole) -> String {
        modeItems(day: day, role: role).filter { !$0.done && !$0.title.isEmpty }.prefix(3)
            .map { [$0.time, $0.title].filter { !$0.isEmpty }.joined(separator: " ") }.joined(separator: " · ")
    }
    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
    func items(on date: Date = Date()) -> [PlanItem] { entries[Self.key(for: date), default: []] }
    var todaySummary: String {
        let rows = items().filter { !$0.done && !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
        return String(rows.prefix(3).map { [$0.time, $0.title].filter { !$0.isEmpty }.joined(separator: " ") }.joined(separator: " · ").prefix(100))
    }
}
struct DDay {
    static func label(target: Date, today: Date = Date(), calendar: Calendar = .current) -> String {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: target)).day ?? 0
        if days == 0 { return "D-DAY" }
        return days > 0 ? "D−\(days)" : "D+\(-days)"
    }
}
