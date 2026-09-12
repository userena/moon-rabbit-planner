import SwiftUI

struct GoalProgressView: View {
    @ObservedObject var state: PetState
    let date: Date
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(state.language == .ko ? "목표 달성도" : "Goal progress").font(.system(size: 20, weight: .semibold))
            Text(state.language == .ko ? "완료한 일정 수 / 목표 · 선택한 플래너 모드 기준" : "Completed tasks / target · selected planner mode").font(.caption).foregroundStyle(.secondary)
            ForEach(["day", "week", "month"], id: \.self) { period in
                GoalProgressRow(state: state, date: date, period: period)
            }
        }.padding(20).plannerSurface(state.appearance)
    }
}

struct GoalProgressRow: View {
    @ObservedObject var state: PetState
    let date: Date
    let period: String
    @AppStorage private var target: Int
    @AppStorage private var storedColor: Data
    init(state: PetState, date: Date, period: String) {
        self.state = state; self.date = date; self.period = period
        _target = AppStorage(wrappedValue: period == "day" ? 3 : period == "week" ? 15 : 60, "progressTarget-" + period)
        _storedColor = AppStorage(wrappedValue: Data(), "progressColor-" + period)
    }
    var title: String {
        if state.language == .ko { return period == "day" ? "일간 목표" : period == "week" ? "주간 목표" : "월간 목표" }
        return period == "day" ? "Daily goal" : period == "week" ? "Weekly goal" : "Monthly goal"
    }
    var barColor: PetColor { (try? JSONDecoder().decode(PetColor.self, from: storedColor)) ?? state.appearance.plannerAccent }
    var count: Int {
        var calendar = Calendar.current; calendar.firstWeekday = 2; calendar.minimumDaysInFirstWeek = 4
        let component: Calendar.Component = period == "day" ? .day : period == "week" ? .weekOfYear : .month
        guard let range = calendar.dateInterval(of: component, for: date) else { return 0 }
        var day = range.start, total = 0
        while day < range.end {
            total += state.plan.modeItems(day: DailyPlan.key(for: day), role: state.activeRole).filter { $0.done && !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }; day = next
        }
        return total
    }
    var body: some View {
        VStack(spacing: 7) {
            HStack {
                Text(title).fontWeight(.semibold)
                Spacer()
                Text("\(count) / \(max(1, target))").monospacedDigit()
                ColorPicker(state.language == .ko ? "\(title) 막대 색" : "\(title) bar color", selection: Binding(get: { barColor.color }, set: { storedColor = (try? JSONEncoder().encode(PetColor($0))) ?? Data() }), supportsOpacity: false).labelsHidden()
            }
            ProgressView(value: Double(min(count, max(1, target))), total: Double(max(1, target)))
                .tint(barColor.color).controlSize(.large)
                .accessibilityLabel(title).accessibilityValue("\(count) / \(max(1, target))")
            Stepper(value: $target, in: 1...1000) {
                Text(state.language == .ko ? "목표 \(target)개" : "Target: \(target) tasks").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
