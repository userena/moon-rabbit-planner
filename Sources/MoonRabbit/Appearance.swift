import SwiftUI
import AppKit

struct PetColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    init(_ red: Double, _ green: Double, _ blue: Double) {
        self.red = red; self.green = green; self.blue = blue
    }
    init(_ color: Color) {
        let rgb = NSColor(color).usingColorSpace(.sRGB) ?? .white
        self.init(Double(rgb.redComponent), Double(rgb.greenComponent), Double(rgb.blueComponent))
    }
    var color: Color { Color(red: red, green: green, blue: blue) }
    var ink: Color {
        func linear(_ c: Double) -> Double { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        let luminance = 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
        return luminance > 0.179 ? .black : .white
    }
}
struct PetAppearance: Codable, Equatable {
    var plannerTitle = ""
    var plannerLogo: String? = nil
    var milestoneHeading = ""
    var ddayPrefix = "D"
    var plannerBackground = PetColor(0.96, 0.95, 0.97)
    var plannerCard = PetColor(1, 1, 1)
    var plannerAccent = PetColor(0.9332719445228577, 0.4071231484413147, 0.7533228397369385)
    var bubbleBackground = PetColor(1, 0.96, 0.88)
    var bubbleBorder = PetColor(0.78, 0.62, 0.48)
    func resolvedPlannerTitle(language: AppLanguage) -> String {
        let title = plannerTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? PetStrings.text("달토끼 플래너", language: language) : title
    }
    mutating func updateLegacyPlannerPalette() {
        if plannerBackground == PetColor(0.97, 0.96, 0.92), plannerCard == PetColor(1, 1, 1),
           plannerAccent == PetColor(0.40, 0.55, 0.46) {
            plannerBackground = PetAppearance().plannerBackground
            plannerAccent = PetAppearance().plannerAccent
        }
    }
    func dayLabel(target: Date, today: Date = Date(), calendar: Calendar = .current) -> String {
        let label = DDay.label(target: target, today: today, calendar: calendar)
        let prefix = ddayPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prefix.isEmpty, prefix != "D" else { return label }
        return label == "D-DAY" ? prefix + " 0" : prefix + " " + label.dropFirst()
    }
}

struct AppearanceView: View {
    @ObservedObject var state: PetState
    let save: () -> Void
    func color(_ key: WritableKeyPath<PetAppearance, PetColor>) -> Binding<Color> {
        Binding(get: { state.appearance[keyPath: key].color }, set: { state.appearance[keyPath: key] = PetColor($0) })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(state.tr("문구와 색상 꾸미기")).font(.headline)
            PlannerLogoMenu(state: state)
            Text(state.tr("플래너 제목")).font(.caption)
            TextField(state.tr("달토끼 플래너"), text: $state.appearance.plannerTitle)
            Text(state.tr("디데이 영역 제목")).font(.caption)
            TextField(state.tr("기다리는 그날"), text: $state.appearance.milestoneHeading)
            Text(state.tr("디데이 표시 문구")).font(.caption)
            TextField("D", text: $state.appearance.ddayPrefix)
            Text(state.tr("예: 마감 → 마감 −7 · 날짜 계산은 유지돼요.")).font(.caption2).foregroundStyle(.secondary)
            Divider()
            ColorPicker(state.tr("플래너 배경"), selection: color(\.plannerBackground), supportsOpacity: false)
            ColorPicker(state.tr("플래너 카드"), selection: color(\.plannerCard), supportsOpacity: false)
            ColorPicker(state.tr("플래너 강조색"), selection: color(\.plannerAccent), supportsOpacity: false)
            ColorPicker(state.tr("말풍선 배경"), selection: color(\.bubbleBackground), supportsOpacity: false)
            ColorPicker(state.tr("말풍선 테두리"), selection: color(\.bubbleBorder), supportsOpacity: false)
            Text(state.tr("색상은 바로 적용되며 글자색은 밝기에 맞춰 바뀝니다.")).font(.caption2).foregroundStyle(.secondary)
            HStack {
                Button(state.tr("기본 색상")) {
                    let defaults = PetAppearance()
                    state.appearance.plannerBackground = defaults.plannerBackground
                    state.appearance.plannerCard = defaults.plannerCard
                    state.appearance.plannerAccent = defaults.plannerAccent
                    state.appearance.bubbleBackground = defaults.bubbleBackground
                    state.appearance.bubbleBorder = defaults.bubbleBorder
                }
                Spacer()
                Button(state.tr(state.saved ? "저장됨 ✓" : "저장"), action: save).buttonStyle(.borderedProminent)
            }
        }.textFieldStyle(.roundedBorder).padding(18).frame(width: 310)
            .settingsSurface()
    }
}
