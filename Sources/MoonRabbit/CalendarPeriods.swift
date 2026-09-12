import SwiftUI

struct CalendarPeriod: Codable, Identifiable {
    var id = UUID()
    var name: String
    var start: Date
    var end: Date
    var color: PetColor
    func includes(_ date: Date) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        return day >= Calendar.current.startOfDay(for: start) && day <= Calendar.current.startOfDay(for: end)
    }
}
final class CalendarPeriods: ObservableObject {
    static let shared = CalendarPeriods()
    @Published var items: [CalendarPeriod] {
        didSet { if let data = try? JSONEncoder().encode(items) { UserDefaults.standard.set(data, forKey: "calendarPeriodsV1") } }
    }
    init() { items = (try? JSONDecoder().decode([CalendarPeriod].self, from: UserDefaults.standard.data(forKey: "calendarPeriodsV1") ?? Data())) ?? [] }
    func on(_ date: Date) -> [CalendarPeriod] { items.filter { $0.includes(date) } }
}
struct CalendarPeriodBadges: View {
    @ObservedObject private var periods = CalendarPeriods.shared
    let date: Date
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(periods.on(date)) { item in
                Text(item.name).font(.caption.weight(.medium)).lineLimit(1).padding(.horizontal, 6).padding(.vertical, 3)
                    .foregroundStyle(item.color.ink).background(item.color.color, in: RoundedRectangle(cornerRadius: 5))
            }
        }
    }
}
struct CalendarPeriodManager: View {
    @ObservedObject private var periods = CalendarPeriods.shared
    @ObservedObject var state: PetState
    @State private var name = ""
    @State private var start = Date()
    @State private var end = Date()
    @State private var color = Color.pink
    @State private var editing: UUID?
    private func t(_ ko: String, _ en: String) -> String { state.language == .ko ? ko : en }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(t("행사 · 시험 기간", "Events & exam periods")).font(.title2.weight(.semibold))
            Text(t("해당 날짜 칸에 선택한 색을 표시합니다. 겹치면 마지막에 추가한 기간 색을 사용하고, 이름은 모두 표시해요.", "Date cells use your color. Overlaps use the last added period’s color; all names remain visible.")).font(.caption).foregroundStyle(.secondary)
            TextField(t("기간 이름", "Period name"), text: $name).textFieldStyle(.roundedBorder)
            DatePicker(t("시작일", "Start date"), selection: $start, displayedComponents: .date)
            DatePicker(t("종료일", "End date"), selection: $end, in: Calendar.current.startOfDay(for: start)..., displayedComponents: .date)
            ColorPicker(t("기간 배경색", "Period background color"), selection: $color, supportsOpacity: false)
            Button(t(editing == nil ? "기간 추가" : "기간 수정 저장", editing == nil ? "Add period" : "Save period")) {
                let item = CalendarPeriod(id: editing ?? UUID(), name: name.trimmingCharacters(in: .whitespacesAndNewlines), start: start, end: max(start, end), color: PetColor(color))
                if let i = periods.items.firstIndex(where: { $0.id == editing }) { periods.items[i] = item } else { periods.items.append(item) }
                editing = nil; name = ""
            }.buttonStyle(.borderedProminent).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(periods.items) { item in
                        HStack {
                            Circle().fill(item.color.color).frame(width: 12, height: 12)
                            VStack(alignment: .leading) { Text(item.name); Text("\(DailyPlan.key(for: item.start)) → \(DailyPlan.key(for: item.end))").font(.caption).foregroundStyle(.secondary) }
                            Spacer()
                            Button(t("편집", "Edit")) { editing = item.id; name = item.name; start = item.start; end = item.end; color = item.color.color }
                            Button(role: .destructive) { periods.items.removeAll { $0.id == item.id }; if editing == item.id { editing = nil; name = "" } } label: { Image(systemName: "trash") }.help(t("기간 삭제", "Delete period"))
                        }
                    }
                }
            }.frame(maxHeight: 210)
        }.padding(24).frame(width: 480)
            .onChange(of: start) { value in if end < value { end = value } }
    }
}
struct CalendarPeriodTint: ViewModifier {
    @ObservedObject private var periods = CalendarPeriods.shared
    let date: Date
    func body(content: Content) -> some View {
        content.background(periods.on(date).last?.color.color.opacity(0.18) ?? .clear, in: RoundedRectangle(cornerRadius: 10))
    }
}
