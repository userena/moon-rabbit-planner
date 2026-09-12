import SwiftUI

struct RabbitAlarm: Codable, Identifiable {
    var id = UUID()
    var title = ""
    var date = Date().addingTimeInterval(3600)
    var daily = false
    var enabled = true
    mutating func consumeIfDue(now: Date, calendar: Calendar = .current) -> Bool {
        guard enabled, now >= date else { return false }
        if daily {
            let components = calendar.dateComponents([.hour, .minute], from: date)
            date = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)!
        } else { enabled = false }
        return true
    }
}
struct AlarmSettingsView: View {
    @ObservedObject var state: PetState
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(state.tr("알람")).font(.headline)
                Spacer()
                Button(state.tr("알람 추가")) { state.alarms.append(RabbitAlarm()) }
            }
            Text(state.tr("앱이 실행 중일 때 소리와 말풍선으로 알려드려요. 잠자기 중 지난 알람은 깨어나면 한 번 알려드려요.")).font(.caption2).foregroundStyle(.secondary)
            ScrollView {
                VStack(spacing: 12) {
                    ForEach($state.alarms) { $alarm in
                        AlarmRow(state: state, alarm: $alarm)
                    }
                }
            }.frame(height: 260)
            Text(state.tr("변경 사항은 자동 저장돼요.")).font(.caption2).foregroundStyle(.secondary)
        }.padding(16).frame(width: 390)
    }
}

struct AlarmRow: View {
    @ObservedObject var state: PetState
    @Binding var alarm: RabbitAlarm
    var minute: Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: alarm.date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle("", isOn: $alarm.enabled).labelsHidden().accessibilityLabel(state.tr("알람 켜기"))
                TextField(state.tr("알람 메모"), text: $alarm.title).textFieldStyle(.roundedBorder)
                Button("−") { state.alarms.removeAll { $0.id == alarm.id } }.accessibilityLabel(state.tr("알람 삭제"))
            }
            HStack {
                DatePicker("", selection: $alarm.date, displayedComponents: .date).labelsHidden()
                ScrollTimePicker(title: state.tr("알람 시각"), display: PlanningTimeOptions.clock(minute), options: Array(0..<1440), selected: minute, label: PlanningTimeOptions.clock, select: chooseTime).frame(width: 80)
                Toggle(state.tr("매일"), isOn: $alarm.daily).toggleStyle(.checkbox)
            }.font(.caption)
        }.padding(10).background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 9))
    }
    func chooseTime(_ value: Int) {
        alarm.date = Calendar.current.date(bySettingHour: value / 60, minute: value % 60, second: 0, of: alarm.date)!
    }
}
