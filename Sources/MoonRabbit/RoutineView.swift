import SwiftUI

struct RoutineRecord: Codable {
    var breakfast = ""
    var lunch = ""
    var dinner = ""
    var snack = ""
    var note = ""
    var bedtime = 1350
    var wake = 420
    var sleepRecorded = false
    var exercise: String? = nil
    var rest: String? = nil
    var hobby: String? = nil
    var meetup: String? = nil
    var sleepMinutes: Int { (wake - bedtime + 1440) % 1440 }
}
struct RoutineView: View {
    @ObservedObject var state: PetState
    let date: Date
    let roulette: () -> Void
    @AppStorage("routineRecordsV1") private var stored = Data()
    private var key: String { DailyPlan.key(for: date) }
    private var record: RoutineRecord { (try? JSONDecoder().decode([String: RoutineRecord].self, from: stored))?[key] ?? RoutineRecord() }
    private func binding<T>(_ path: WritableKeyPath<RoutineRecord, T>) -> Binding<T> {
        Binding(get: { record[keyPath: path] }, set: { value in
            var records = (try? JSONDecoder().decode([String: RoutineRecord].self, from: stored)) ?? [:]
            var row = records[key] ?? RoutineRecord(); row[keyPath: path] = value; records[key] = row
            if let data = try? JSONEncoder().encode(records) { stored = data }
        })
    }
    private func t(_ ko: String, _ en: String) -> String { state.language == .ko ? ko : en }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(t("생활관리", "Daily life")).font(.title.weight(.semibold))
            Text(t("선택한 날짜의 생활 기록 · 자동 저장", "Daily routine for the selected date · auto-saved")).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 16) {
                HStack { Label(t("식사 기록", "Meal log"), systemImage: "fork.knife").font(.title2); Spacer(); Button(t("식사 메뉴 룰렛", "Meal roulette"), action: roulette) }
                meal(t("아침", "Breakfast"), text: binding(\.breakfast))
                meal(t("점심", "Lunch"), text: binding(\.lunch))
                meal(t("저녁", "Dinner"), text: binding(\.dinner))
                meal(t("간식 · 음료", "Snacks & drinks"), text: binding(\.snack))
            }.padding(22).plannerSurface(state.appearance)
            VStack(alignment: .leading, spacing: 16) {
                Label(t("수면 기록", "Sleep log"), systemImage: "moon.zzz").font(.title2)
                Text(t("선택한 날짜에 일어난 수면을 기록하세요. 밤을 넘긴 시간도 계산해요.", "Record sleep ending on the selected date. Overnight sleep is included.")).font(.subheadline).foregroundStyle(.secondary)
                timePicker(t("잠든 시간", "Bedtime"), selection: binding(\.bedtime))
                timePicker(t("일어난 시간", "Wake time"), selection: binding(\.wake))
                Toggle(t("수면 기록 완료", "Sleep recorded"), isOn: binding(\.sleepRecorded))
                Text(record.sleepRecorded ? t("수면 \(record.sleepMinutes / 60)시간 \(record.sleepMinutes % 60)분", "Sleep: \(record.sleepMinutes / 60)h \(record.sleepMinutes % 60)m") : t("아직 기록하지 않았어요", "Not recorded yet")).font(.title2.weight(.semibold))
                meal(t("생활 메모", "Routine notes"), text: binding(\.note))
            }.padding(22).plannerSurface(state.appearance)
            lifestyle(t("운동", "Exercise"), symbol: "figure.walk", path: \.exercise)
            lifestyle(t("휴식", "Rest"), symbol: "cup.and.saucer", path: \.rest)
            lifestyle(t("취미", "Hobbies"), symbol: "paintpalette", path: \.hobby)
            lifestyle(t("모임", "Meetups"), symbol: "person.2", path: \.meetup)
        }
    }
    private func lifestyle(_ title: String, symbol: String, path: WritableKeyPath<RoutineRecord, String?>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol).font(.title2)
            TextField(t("계획 · 시간 · 기록", "Plan · time · notes"), text: Binding(get: { record[keyPath: path] ?? "" }, set: { binding(path).wrappedValue = $0 }), axis: .vertical).lineLimit(3...6).textFieldStyle(.roundedBorder).accessibilityLabel(title)
        }.padding(22).plannerSurface(state.appearance)
    }
    private func meal(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) { Text(title).fontWeight(.medium); TextField(title, text: text, axis: .vertical).lineLimit(1...4).textFieldStyle(.roundedBorder).accessibilityLabel(title) }
    }
    private func timePicker(_ title: String, selection: Binding<Int>) -> some View {
        Picker(title, selection: selection) { ForEach(Array(stride(from: 0, to: 1440, by: 10)), id: \.self) { value in Text(String(format: "%02d:%02d", value / 60, value % 60)).tag(value) } }.frame(maxWidth: 300)
    }
}
