import SwiftUI

struct MonthlyRecord: Codable {
    var goal = ""
    var note = ""
    var tasks: [PlanItem] = []
    static func key(date: Date, role: WorkRole, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year!, parts.month!) + ":" + role.rawValue
    }
}
struct MonthRecordView: View {
    @ObservedObject var state: PetState
    let date: Date
    let role: WorkRole
    var key: String { MonthlyRecord.key(date: date, role: role) }
    var record: Binding<MonthlyRecord> {
        Binding(get: { state.plan.monthlyRecords[key] ?? MonthlyRecord() }, set: { state.plan.monthlyRecords[key] = $0 })
    }
    var body: some View {
        VStack(spacing: 16) {
        MonthlyGoalCard(state: state, date: date, role: role)
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(state.tr("월간 메모")).font(.system(size: 18, weight: .semibold))
                TextEditor(text: record.note).font(.system(size: 14)).scrollContentBackground(.hidden)
                    .frame(height: 90).accessibilityLabel(state.tr("월간 메모"))
            }.frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(state.tr("이번 달 할 일")).font(.system(size: 18, weight: .semibold))
                    Spacer()
                    Button("+") { state.plan.monthlyRecords[key, default: MonthlyRecord()].tasks.append(PlanItem()) }
                        .accessibilityLabel(state.tr("월간 할 일 추가"))
                }
                ScrollView {
                    VStack(spacing: 6) {
                        if record.wrappedValue.tasks.isEmpty { Text(state.tr("+ 버튼으로 월간 할 일을 적어보세요.")).font(.system(size: 13)).foregroundStyle(.secondary) }
                        ForEach(record.tasks) { $task in
                            HStack {
                                Toggle("", isOn: $task.done).labelsHidden().accessibilityLabel(state.tr("완료"))
                                TextField(state.tr("할 일"), text: $task.title).strikethrough(task.done).textFieldStyle(.roundedBorder)
                                Button("−") { state.plan.monthlyRecords[key]?.tasks.removeAll { $0.id == task.id } }.accessibilityLabel(state.tr("월간 할 일 삭제"))
                            }
                        }
                    }
                }.frame(height: 132)
            }.frame(maxWidth: .infinity)
        }.padding(20).plannerSurface(state.appearance)
        }
    }
}
struct MonthDayEditor: View {
    @ObservedObject var state: PetState
    let day: Date
    let role: WorkRole
    let save: () -> Void
    let openDay: () -> Void
    var key: String { DailyPlan.key(for: day) }
    var tasks: Binding<[PlanItem]> {
        Binding(get: { state.plan.modeItems(day: key, role: role) }, set: { state.plan.setModeItems($0, day: key, role: role) })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(day, format: .dateTime.month().day().weekday()).font(.headline)
            Text(state.tr("여기서 적은 일정은 일간 플래너에도 함께 표시돼요.")).font(.caption2).foregroundStyle(.secondary)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(tasks) { $task in
                        HStack {
                            Toggle("", isOn: $task.done).labelsHidden().accessibilityLabel(state.tr("완료"))
                            TextField(state.tr("할 일"), text: $task.title).textFieldStyle(.roundedBorder)
                            Button("−") { tasks.wrappedValue.removeAll { $0.id == task.id } }.accessibilityLabel(state.tr("일정 삭제"))
                        }
                    }
                }
            }.frame(height: 160)
            HStack {
                Button(state.tr("+ 일정 추가")) { tasks.wrappedValue.append(PlanItem()) }
                Spacer()
                Button(state.tr("일간 자세히"), action: openDay)
                Button(state.tr(state.saved ? "저장됨 ✓" : "저장"), action: save).buttonStyle(.borderedProminent)
            }
        }.padding(16).frame(width: 430)
    }
}
