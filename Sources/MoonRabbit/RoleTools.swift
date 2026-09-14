import SwiftUI

enum WorkRole: String, CaseIterable, Codable {
    case developer, designer, planner, soloStartup, student, office, startupTeam
    var title: String {
        switch self {
        case .developer: return "개발자"
        case .designer: return "디자이너"
        case .planner: return "기획자"
        case .student: return "학생"
        case .office: return "회사원"
        case .soloStartup: return "1인 스타트업"
        case .startupTeam: return "스타트업 팀"
        }
    }
    var fields: [String] {
        switch self {
        case .developer: return ["재현 방법과 기대 결과", "원인과 해결 아이디어", "다음에 이어 할 작업"]
        case .designer: return ["디자인 목적과 사용자", "참고 자료와 링크", "피드백과 수정 방향"]
        case .planner: return ["해결할 문제와 성공 기준", "결정 사항과 근거", "위험 요소와 다음 행동"]
        case .student: return ["오늘 공부할 범위", "틀린 이유와 핵심 개념", "다시 복습할 내용"]
        case .office: return ["회의 안건과 메모", "결정 사항", "후속 업무 · 담당자 · 기한"]
        case .soloStartup: return ["고객 문제와 이번 주 가설", "검증 실험과 성공 지표", "매출 · 비용 · 다음 고객 행동"]
        case .startupTeam: return ["이번 스프린트 목표", "팀 결정과 의존 작업", "막힌 일과 지원 요청"]
        }
    }
    var checks: [String] {
        switch self {
        case .developer: return ["재현 확인", "테스트 통과", "변경 내용 검토"]
        case .designer: return ["가독성 확인", "상태별 화면 확인", "전달 파일 정리"]
        case .planner: return ["요구사항 확인", "우선순위 결정", "담당자와 일정 확인"]
        case .student: return ["개념 복습", "문제 풀이", "오답 정리"]
        case .office: return ["오늘의 우선순위", "후속 업무 확인", "내일 할 일 정리"]
        case .soloStartup: return ["고객 인터뷰", "작은 실험 출시", "지표 확인과 다음 실험"]
        case .startupTeam: return ["담당 업무 합의", "진행 상황 공유", "스프린트 결과 검토"]
        }
    }
    var categoryTitle: String {
        switch self {
        case .developer: return "모듈"
        case .designer: return "화면"
        case .planner: return "기능"
        case .soloStartup: return "실험"
        case .student: return "과목"
        case .office: return "업무"
        case .startupTeam: return "프로젝트"
        }
    }
    var taskHeading: String {
        switch self {
        case .developer: return "개발 작업과 검증"
        case .designer: return "디자인 작업과 피드백"
        case .planner: return "요구사항과 실행 계획"
        case .soloStartup: return "고객 검증과 성장 실험"
        case .student: return "공부와 과제 계획"
        case .office: return "업무와 후속 조치"
        case .startupTeam: return "팀 스프린트 업무"
        }
    }
    var workArtwork: String {
        switch self {
        case .developer, .office, .soloStartup: return "workLaptop"
        case .designer: return "workDesign"
        case .student: return "workStudy"
        case .planner, .startupTeam: return "workPlan"
        }
    }
    var usesOwner: Bool { self == .startupTeam || self == .office }
    func tasks(language: AppLanguage) -> [PlanItem] {
        checks.map { PlanItem(title: PetStrings.text($0, language: language), category: PetStrings.text(title, language: language), minutes: 30) }
    }
}
struct RolePage: Codable {
    var notes: [String: String] = [:]
    var checked: [String: Bool] = [:]
    var colors = [PetColor(0.4, 0.55, 0.46), PetColor(0.8, 0.6, 0.65), PetColor(0.97, 0.94, 0.88)]
    init() {}
    enum CodingKeys: String, CodingKey { case notes, checked, colors }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        notes = try c.decodeIfPresent([String: String].self, forKey: .notes) ?? [:]
        checked = try c.decodeIfPresent([String: Bool].self, forKey: .checked) ?? [:]
        let saved = try c.decodeIfPresent([PetColor].self, forKey: .colors) ?? []
        for index in colors.indices where saved.indices.contains(index) { colors[index] = saved[index] }
    }
}
struct StudyTotal: Equatable {
    let subject: String
    let planned: Int
    let completed: Int
    static func summarize(_ items: [PlanItem], fallback: String) -> [StudyTotal] {
        let named = items.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let groups = Dictionary(grouping: named) { $0.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : $0.category }
        return groups.keys.sorted().map { key in
            let tasks = groups[key]!
            return StudyTotal(subject: key, planned: tasks.reduce(0) { $0 + max(0, min(1440, $1.minutes)) }, completed: tasks.filter(\.done).reduce(0) { $0 + max(0, min(1440, $1.minutes)) })
        }
    }
}
struct RoleToolsView: View {
    @ObservedObject var state: PetState
    let dayKey: String
    let focus: (Int) -> Void
    let role: WorkRole
    var key: String { dayKey + ":" + role.rawValue }
    var page: RolePage { state.plan.rolePages[key] ?? RolePage() }
    func note(_ field: String) -> Binding<String> {
        Binding(get: { page.notes[field, default: ""] }, set: { state.plan.rolePages[key, default: RolePage()].notes[field] = $0 })
    }
    func checked(_ field: String) -> Binding<Bool> {
        Binding(get: { page.checked[field, default: false] }, set: { state.plan.rolePages[key, default: RolePage()].checked[field] = $0 })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(state.tr(role.title) + " · " + state.tr("작업 노트")).font(.system(size: 13, weight: .semibold))
            VStack(alignment: .leading, spacing: 12) {
                Text(state.tr("날짜와 직군별로 따로 저장돼요.")).font(.caption2).foregroundStyle(.secondary)
                ForEach(role.fields, id: \.self) { field in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(state.tr(field)).font(.system(size: 13))
                        TextEditor(text: note(field)).font(.system(size: 13)).frame(height: 58)
                            .scrollContentBackground(.hidden).padding(4)
                            .background(state.appearance.plannerBackground.color.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
                            .accessibilityLabel(state.tr(field))
                    }
                }
                if role == .designer {
                    HStack {
                        Text(state.tr("작업 팔레트")).font(.system(size: 13))
                        ForEach(0..<3, id: \.self) { index in
                            ColorPicker("", selection: Binding(get: { page.colors[index].color }, set: { state.plan.rolePages[key, default: RolePage()].colors[index] = PetColor($0) }), supportsOpacity: false)
                                .labelsHidden().accessibilityLabel("\(state.tr("작업 팔레트")) \(index + 1)")
                        }
                    }
                }
                if role == .student {
                    Text(state.tr("과목별 예정 / 완료 분량 (분)")).font(.system(size: 13))
                    ForEach(StudyTotal.summarize(state.plan.modeItems(day: dayKey, role: role), fallback: state.tr("미분류")), id: \.subject) { total in
                        HStack { Text(total.subject); Spacer(); Text("\(total.planned) / \(total.completed)").monospacedDigit() }.font(.system(size: 13))
                    }
                    Text(state.tr("일정의 분류에 과목을 적으세요. 완료 분량은 체크한 일정의 예정 시간입니다.")).font(.caption2).foregroundStyle(.secondary)
                }
                ForEach(role.checks, id: \.self) { field in
                    Toggle(state.tr(field), isOn: checked(field)).toggleStyle(.checkbox).font(.system(size: 13))
                }
                HStack {
                    Button(state.tr("체크리스트를 일정에 추가")) {
                        state.plan.setModeItems(state.plan.modeItems(day: dayKey, role: role) + role.tasks(language: state.language), day: dayKey, role: role)
                    }
                    Spacer()
                    Button(state.tr("25분 집중")) { focus(25) }
                    Button(state.tr("50분 집중")) { focus(50) }
                }.controlSize(.small)
            }.padding(.top, 12)
        }.padding(16).background(state.appearance.plannerCard.color, in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(state.appearance.plannerCard.ink)
    }
}
