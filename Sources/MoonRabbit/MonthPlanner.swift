import SwiftUI

enum PlannerPeriod: String, CaseIterable {
    case week, month, days100, days200, year
    var title: String {
        switch self { case .week: return "1주일"; case .month: return "1개월"; case .days100: return "100일"; case .days200: return "200일"; case .year: return "1년" }
    }
    func end(start: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: start)
        let exclusive: Date
        switch self {
        case .week: exclusive = calendar.date(byAdding: .day, value: 7, to: start)!
        case .month: exclusive = calendar.date(byAdding: .month, value: 1, to: start)!
        case .year: exclusive = calendar.date(byAdding: .year, value: 1, to: start)!
        case .days100: exclusive = calendar.date(byAdding: .day, value: 100, to: start)!
        case .days200: exclusive = calendar.date(byAdding: .day, value: 200, to: start)!
        }
        return calendar.date(byAdding: .day, value: -1, to: exclusive)!
    }
}
struct MonthPlannerView: View {
    @ObservedObject var state: PetState
    let role: WorkRole
    @Binding var date: Date
    let start: Date
    let end: Date
    let openDay: () -> Void
    let save: () -> Void
    @State private var editingDay: Date? = nil
    var calendar: Calendar { var c = Calendar.current; c.locale = Locale(identifier: state.language == .ko ? "ko_KR" : "en_US"); return c }
    var monthStart: Date { calendar.date(from: calendar.dateComponents([.year, .month], from: date))! }
    var days: [Date?] {
        let offset = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        let count = calendar.range(of: .day, in: .month, for: date)!.count
        return Array(repeating: nil, count: offset) + (0..<count).map { calendar.date(byAdding: .day, value: $0, to: monthStart)! }
    }
    func move(_ delta: Int) {
        let next = calendar.date(byAdding: .month, value: delta, to: monthStart)!
        date = min(max(next, calendar.startOfDay(for: start)), end)
    }
    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button { move(-1) } label: { Image(systemName: "chevron.left") }.disabled(monthStart <= calendar.date(from: calendar.dateComponents([.year, .month], from: start))!)
                Text(date, format: .dateTime.year().month(.wide)).font(.title2)
                Button { move(1) } label: { Image(systemName: "chevron.right") }.disabled(calendar.isDate(date, equalTo: end, toGranularity: .month))
                Spacer()
                Text(state.tr("날짜를 눌러 바로 기록하세요.")).font(.system(size: 13)).foregroundStyle(.secondary)
            }
            MonthRecordView(state: state, date: date, role: role)
            let symbols = calendar.shortWeekdaySymbols
            HStack {
                ForEach(0..<7, id: \.self) { index in
                    Text(symbols[(calendar.firstWeekday - 1 + index) % 7]).font(.system(size: 13)).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 7), spacing: 7) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        let available = day >= calendar.startOfDay(for: start) && day <= end
                        let tasks = state.plan.modeItems(day: DailyPlan.key(for: day), role: role).filter { !$0.title.isEmpty }
                        Button {
                            editingDay = day
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(calendar.component(.day, from: day))").font(.system(size: 16, weight: calendar.isDateInToday(day) ? .bold : .regular))
                                ForEach(tasks.prefix(2)) { item in
                                    HStack(spacing: 3) {
                                        Circle().fill((item.color ?? state.appearance.plannerAccent).color).frame(width: 5, height: 5)
                                        Text(item.title).lineLimit(1).strikethrough(item.done).font(.system(size: 12))
                                    }
                                }
                                Spacer(minLength: 0)
                                if !tasks.isEmpty { Text("\(tasks.filter(\.done).count)/\(tasks.count)").font(.system(size: 12)).foregroundStyle(.secondary) }
                            }.padding(8).frame(maxWidth: .infinity, minHeight: 108, maxHeight: 108, alignment: .topLeading)
                                .background(state.appearance.plannerCard.color, in: RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(calendar.isDateInToday(day) ? state.appearance.plannerAccent.color : .clear, lineWidth: 1.5))
                                .foregroundStyle(state.appearance.plannerCard.ink).opacity(available ? 1 : 0.3)
                        }.buttonStyle(.plain).disabled(!available)
                            .popover(isPresented: Binding(get: { editingDay == day }, set: { if !$0 { editingDay = nil } })) {
                                MonthDayEditor(state: state, day: day, role: role, save: save) {
                                    date = day; editingDay = nil; openDay()
                                }
                            }
                    } else { Color.clear.frame(height: 108) }
                }
            }
        }
    }
}
