import SwiftUI

struct WeekPlannerView: View {
    @ObservedObject var state: PetState
    @Binding var date: Date
    let openDay: () -> Void
    @AppStorage("weeklyGoalsV1") private var storedGoals = Data()
    private var goal: Binding<String> {
        let key = DailyPlan.key(for: days.first ?? date) + ":" + state.activeRole.rawValue
        return Binding(get: { (try? JSONDecoder().decode([String: String].self, from: storedGoals))?[key] ?? "" }, set: { value in
            var goals = (try? JSONDecoder().decode([String: String].self, from: storedGoals)) ?? [:]
            goals[key] = value
            if let data = try? JSONEncoder().encode(goals) { storedGoals = data }
        })
    }
    private var weeklyAppearance: PetAppearance {
        var result = state.appearance
        let card = result.plannerCard, accent = result.plannerAccent
        result.plannerCard = PetColor(card.red * 0.94 + accent.red * 0.06, card.green * 0.94 + accent.green * 0.06, card.blue * 0.94 + accent.blue * 0.06)
        return result
    }
    private var days: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button { date = Calendar.current.date(byAdding: .day, value: -7, to: date) ?? date } label: { Label(state.language == .ko ? "이전 주" : "Previous week", systemImage: "chevron.left") }
                Spacer()
                Text(state.language == .ko ? "한 주의 일정" : "This week").font(.title2.weight(.semibold))
                Spacer()
                Button { date = Calendar.current.date(byAdding: .day, value: 7, to: date) ?? date } label: { Label(state.language == .ko ? "다음 주" : "Next week", systemImage: "chevron.right") }
            }
            VStack(alignment: .leading, spacing: 16) {
            PlannerGoalCard(title: state.language == .ko ? "이번 주 목표" : "This week’s goal",
                            subtitle: state.language == .ko ? "주차와 플래너 모드별로 자동 저장돼요." : "Saved automatically for each week and planner mode.",
                            placeholder: state.language == .ko ? "이번 주에 이루고 싶은 일을 적어주세요" : "What would you like to accomplish this week?",
                            goal: goal, appearance: weeklyAppearance) { EmptyView() }
            GoalProgressView(state: state, date: date)
            }.padding(14).background(state.appearance.plannerAccent.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
            ForEach(days, id: \.self) { day in
                VStack(alignment: .leading, spacing: 12) {
                    Button { date = day; openDay() } label: {
                        HStack { Text(day, format: .dateTime.month().day().weekday(.wide)).font(.title3.weight(.semibold)); Spacer(); Text(state.language == .ko ? "일정 편집 ↗" : "Edit day ↗") }
                    }.buttonStyle(.plain)
                    CalendarPeriodBadges(date: day)
                    let rows = state.plan.modeItems(day: DailyPlan.key(for: day), role: state.activeRole).filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }.sorted { ($0.startMinute ?? 1440) < ($1.startMinute ?? 1440) }
                    if rows.isEmpty { Text(state.language == .ko ? "등록한 일정이 없어요." : "No scheduled tasks.").foregroundStyle(.secondary) }
                    ForEach(rows) { row in
                        HStack { Image(systemName: row.done ? "checkmark.circle.fill" : "circle"); Text(row.time).monospacedDigit(); Text(row.title).strikethrough(row.done); Spacer(); Text(state.tr(row.priorityLabel)).font(.caption) }
                    }
                }.padding(20).modifier(CalendarPeriodTint(date: day)).plannerSurface(state.appearance)
            }
        }
    }
}
