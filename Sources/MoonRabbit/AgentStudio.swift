import SwiftUI
import AppKit

struct StudioCategory: Codable, Equatable, Identifiable {
    var id = UUID().uuidString
    var title = ""
    var note = ""
    var done = false
}
struct StudioAgent: Codable, Equatable, Identifiable {
    var id = UUID().uuidString
    var name = ""
    var service = "ChatGPT"
    var task = ""
    var output = ""
    var status = "todo"
    var categories: [StudioCategory]? = nil
    static let services = ["ChatGPT", "Codex", "Gemini", "Claude"]
    var serviceURL: URL { URL(string: ["ChatGPT": "https://chatgpt.com/", "Codex": "https://chatgpt.com/codex", "Gemini": "https://gemini.google.com/", "Claude": "https://claude.ai/"][service] ?? "https://chatgpt.com/")! }
}
struct StudioDocument: Codable, Equatable {
    var project = ""
    var context = ""
    var blueprint = ""
    var agents: [StudioAgent] = []
    static func initial(english: Bool) -> Self {
        Self(agents: zip(english ? ["Planning", "Architecture", "Design", "Development", "Review", "Deployment", "Maintenance"] : ["기획", "설계", "디자인", "개발", "검토", "배포", "유지보수"], ["ChatGPT", "Codex", "ChatGPT", "Codex", "Codex", "Codex", "Codex"]).map { StudioAgent(name: $0.0, service: $0.1) })
    }
    func prompt(for agent: StudioAgent, english: Bool) -> String {
        let flow = agents.map(\.name).joined(separator: " → ")
        let categories = (agent.categories ?? []).map { "• [" + ($0.done ? "✓" : " ") + "] " + $0.title + "\n" + $0.note }.joined(separator: "\n")
        if english { return "Project: \(project)\nContext and requirements:\n\(context)\nBlueprint:\n\(blueprint)\nWorkflow: \(flow)\nYour role: \(agent.name)\nTask:\n\(agent.task)\nExpected deliverable:\n\(agent.output)\nSubcategories:\n\(categories)\nExplain assumptions and report results, validation, and next handoff. Ask if essential information is missing." }
        return "프로젝트: \(project)\n배경과 요구사항:\n\(context)\n설계도:\n\(blueprint)\n작업 흐름: \(flow)\n당신의 역할: \(agent.name)\n담당할 일:\n\(agent.task)\n필요한 결과물:\n\(agent.output)\n하부 카테고리:\n\(categories)\n가정을 명시하고 결과, 확인 내용, 다음 담당자에게 전달할 내용을 정리해주세요. 필수 정보가 부족하면 질문해주세요."
    }
}
struct AgentStudioView: View {
    @ObservedObject var state: PetState
    let date: Date
    @AppStorage("agentStudioV1") private var stored = Data()
    @AppStorage("studioLifecycleExpanded") private var expanded = false
    @State private var document = StudioDocument()
    @State private var loaded = false
    @State private var message = ""
    @State private var preview: StudioAgent?
    @State private var apiPrompt: StudioAgent?
    @Environment(\.plannerContentZoom) private var zoom
    private var english: Bool { state.language == .en }
    private func t(_ ko: String, _ en: String) -> String { english ? en : ko }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text(t("에이전트 작업실", "Agent studio")).font(.system(size: 28 * zoom, weight: .semibold))
                Text(t("역할을 나누고, 설계하고, 지시문을 준비해요.", "Assign roles, map the work, and prepare instructions.")).foregroundStyle(.secondary)
                Text(t("이 기기에 자동 저장 · 복사 후 서비스에 붙여넣어 전송하세요. 서비스 이용 조건은 각 계정을 따릅니다.", "Saved on this device · Paste and send in the service. Your account’s service terms apply.")).font(.caption).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 12) {
                Button(t("선택한 날의 일정 가져오기", "Import selected day’s tasks")) {
                    let tasks = state.plan.modeItems(day: DailyPlan.key(for: date), role: state.activeRole).filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
                    let snapshot = tasks.map { "• " + $0.title }.joined(separator: "\n")
                    if !snapshot.isEmpty { document.context += (document.context.isEmpty ? "" : "\n\n") + DailyPlan.key(for: date) + "\n" + snapshot }
                }
                field(t("프로젝트 이름", "Project name"), text: $document.project)
                field(t("배경 · 요구사항 · 참고 링크", "Context · requirements · references"), text: $document.context)
                field(t("설계 메모 · 구성 요소와 연결 관계", "Blueprint · components and connections"), text: $document.blueprint)
            }.padding(20).plannerSurface(state.appearance)
            VStack(alignment: .leading, spacing: 16) {
                HStack { Text(t("전체 구조도", "Project structure")).font(.title2.weight(.semibold)); Spacer(); Text(t("단계 → 하부 카테고리", "Stages → subcategories")).font(.caption).foregroundStyle(.secondary) }
                Text(document.project.isEmpty ? t("프로젝트", "Project") : document.project).font(.headline).padding(12).frame(maxWidth: .infinity).background(state.appearance.plannerAccent.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), spacing: 10)], alignment: .leading, spacing: 12) {
                    ForEach(document.agents) { agent in
                        Button { preview = agent } label: {
                            VStack(alignment: .leading, spacing: 9) {
                                Text("\((document.agents.firstIndex(where: { $0.id == agent.id }) ?? 0) + 1). " + (agent.name.isEmpty ? t("단계", "Stage") : agent.name)).font(.subheadline.weight(.semibold))
                                Text(agent.service).font(.caption).foregroundStyle(.secondary)
                                Divider()
                                if (agent.categories ?? []).isEmpty { Text(t("하부 카테고리 없음", "No subcategories")).font(.caption).foregroundStyle(.secondary) }
                                ForEach(agent.categories ?? []) { category in
                                    Text((category.done ? "✓ " : "└ ") + (category.title.isEmpty ? t("카테고리", "Category") : category.title)).font(.caption).fixedSize(horizontal: false, vertical: true)
                                }
                            }.padding(12).frame(maxWidth: .infinity, alignment: .topLeading).plannerSurface(state.appearance)
                        }.buttonStyle(.plain)
                    }
                }
            }.padding(20).plannerSurface(state.appearance)
            VStack(alignment: .leading, spacing: 12) {
                Text(t("작업 흐름 설계도", "Workflow blueprint")).font(.headline)
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.2.crop.square.stack").font(.title2)
                        Text(document.project.isEmpty ? t("프로젝트 회의 테이블", "Project meeting table") : document.project).font(.title3.weight(.semibold))
                        Text(t("공통 목표 · 요구사항 · 설계 공유", "Shared goals · requirements · blueprint")).font(.caption).foregroundStyle(.secondary)
                    }.padding(20).frame(maxWidth: .infinity)
                        .background(state.appearance.plannerAccent.color.opacity(0.15), in: Capsule())
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 18)], spacing: 22) {
                        ForEach(document.agents) { agent in
                            Button { preview = agent } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(String(format: "%02d", (document.agents.firstIndex(where: { $0.id == agent.id }) ?? 0) + 1)).font(.caption.monospaced().bold())
                                        Spacer()
                                        Text(agent.status == "done" ? t("완료", "Done") : agent.status == "doing" ? t("진행 중", "In progress") : t("예정", "To do")).font(.caption)
                                    }
                                    HStack(spacing: 14) {
                                        Image(systemName: "desktopcomputer").font(.system(size: 30)).foregroundStyle(state.appearance.plannerAccent.color)
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(agent.name.isEmpty ? t("역할 이름", "Role name") : agent.name).font(.title3.weight(.semibold))
                                            Text(agent.service).font(.caption).foregroundStyle(.secondary)
                                        }
                                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                                        .background(state.appearance.plannerCard.ink.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                                    Text(agent.task.isEmpty ? t("책상을 눌러 지시문 확인", "Tap desk to preview instructions") : agent.task).font(.subheadline).lineLimit(2)
                                    ForEach(agent.categories ?? []) { category in
                                        Text((category.done ? "✓ " : "○ ") + (category.title.isEmpty ? t("하부 카테고리", "Subcategory") : category.title)).font(.caption).lineLimit(1)
                                    }
                                    HStack { Spacer(); RoundedRectangle(cornerRadius: 8).fill(state.appearance.plannerAccent.color.opacity(0.25)).frame(width: 48, height: 14); Spacer() }
                                }.padding(16).plannerSurface(state.appearance)
                            }.buttonStyle(.plain).accessibilityLabel(t("\(agent.name) 책상 · 지시문 확인", "\(agent.name) desk · preview instructions"))
                        }
                    }
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(document.agents) { agent in
                                Text(agent.name.isEmpty ? t("역할 이름", "Role name") : agent.name).font(.subheadline.weight(.semibold))
                                if agent.id != document.agents.last?.id { Image(systemName: "arrow.right").foregroundStyle(state.appearance.plannerAccent.color) }
                            }
                        }.padding(12)
                    }
                }.padding(18).background(state.appearance.plannerCard.ink.opacity(0.025), in: RoundedRectangle(cornerRadius: 16))
                Text(t("카드의 ↑ ↓ 버튼으로 순서를 바꿀 수 있어요. 진행 상태는 직접 기록합니다.", "Use ↑ ↓ to reorder cards. Update progress manually.")).font(.caption).foregroundStyle(.secondary)
            }.padding(20).plannerSurface(state.appearance)
            ForEach($document.agents) { $agent in
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        TextField(t("역할 이름", "Role name"), text: $agent.name).font(.title3.weight(.semibold))
                        Picker(t("서비스", "Service"), selection: $agent.service) { ForEach(StudioAgent.services, id: \.self) { Text($0).tag($0) } }.frame(width: 155)
                        Button("↑") { move(agent.id, offset: -1) }.disabled(agent.id == document.agents.first?.id).help(t("앞으로 이동", "Move earlier"))
                        Button("↓") { move(agent.id, offset: 1) }.disabled(agent.id == document.agents.last?.id).help(t("뒤로 이동", "Move later"))
                        Button(role: .destructive) { document.agents.removeAll { $0.id == agent.id } } label: { Image(systemName: "trash") }.help(t("역할 삭제", "Delete role"))
                    }
                    field(t("담당할 일", "Assigned task"), text: $agent.task)
                    field(t("필요한 결과물", "Expected deliverable"), text: $agent.output)
                    StudioCategoriesEditor(categories: Binding(get: { agent.categories ?? [] }, set: { agent.categories = $0 }), english: english)

                    Picker(t("진행 상태", "Status"), selection: $agent.status) {
                        Text(t("예정", "To do")).tag("todo"); Text(t("진행 중", "In progress")).tag("doing"); Text(t("완료", "Done")).tag("done")
                    }.pickerStyle(.segmented)
                    HStack {
                        Button(t("지시문 확인", "Preview instructions")) { preview = agent }
                        Button(t("내 API 연결", "My API")) { apiPrompt = agent }
                        Button(t("지시문 복사", "Copy instructions")) { copy(agent) }.buttonStyle(.borderedProminent)
                        Link(t("\(agent.service) 열기 ↗", "Open \(agent.service) ↗"), destination: agent.serviceURL)
                    }
                }.padding(20).plannerSurface(state.appearance)
            }
            Button { document.agents.append(StudioAgent()) } label: { Label(t("단계 추가", "Add stage"), systemImage: "plus") }
            if !message.isEmpty { Text(message).foregroundStyle(.secondary) }
        }.textFieldStyle(.roundedBorder)
        .onAppear {
            guard !loaded else { return }
            document = (try? JSONDecoder().decode(StudioDocument.self, from: stored)) ?? .initial(english: english)
            if !expanded {
                let defaults = Set(["기획", "디자인", "개발", "검토"])
                let enDefaults = Set(["Planning", "Design", "Development", "Review"])
                if Set(document.agents.map(\.name)) == defaults || Set(document.agents.map(\.name)) == enDefaults {
                    document.agents.insert(StudioAgent(name: english ? "Architecture" : "설계", service: "Codex"), at: min(1, document.agents.count))
                    document.agents.append(contentsOf: [StudioAgent(name: english ? "Deployment" : "배포", service: "Codex"), StudioAgent(name: english ? "Maintenance" : "유지보수", service: "Codex")])
                }
                expanded = true
            }
            loaded = true
        }
        .onChange(of: document) { value in if loaded, let data = try? JSONEncoder().encode(value) { stored = data } }
        .sheet(item: $apiPrompt) { agent in PersonalAPIView(english: english, initialPrompt: document.prompt(for: agent, english: english)) }
        .sheet(item: $preview) { agent in
            VStack(alignment: .leading, spacing: 16) {
                Text(t("전달할 지시문", "Instructions to send")).font(.title2)
                ScrollView { Text(document.prompt(for: agent, english: english)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
                HStack { Button(t("지시문 복사", "Copy instructions")) { copy(agent) }; Spacer(); Button(t("닫기", "Close")) { preview = nil } }
            }.padding(24).frame(minWidth: 480, idealWidth: 560, minHeight: 400)
        }
    }
    private func field(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.subheadline.weight(.medium))
            TextField(label, text: text, axis: .vertical).lineLimit(2...6).accessibilityLabel(label)
        }
    }
    private func move(_ id: String, offset: Int) {
        guard let i = document.agents.firstIndex(where: { $0.id == id }), document.agents.indices.contains(i + offset) else { return }
        document.agents.swapAt(i, i + offset)
    }
    private func copy(_ agent: StudioAgent) {
        NSPasteboard.general.clearContents()
        let ok = NSPasteboard.general.setString(document.prompt(for: agent, english: english), forType: .string)
        message = ok ? t("복사했어요. 서비스를 열고 붙여넣어 주세요.", "Copied. Open the service and paste your instructions.") : t("복사하지 못했어요. 지시문 확인에서 직접 복사해주세요.", "Copy failed. Select and copy from the preview.")
    }
}

struct StudioCategoriesEditor: View {
    @Binding var categories: [StudioCategory]
    let english: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(english ? "Subcategories" : "하부 카테고리").font(.headline)
            ForEach($categories) { $category in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle(english ? "Done" : "완료", isOn: $category.done).labelsHidden().accessibilityLabel(english ? "Subcategory done" : "하부 카테고리 완료")
                        TextField(english ? "Category name" : "카테고리 이름", text: $category.title)
                        Button(role: .destructive) { categories.removeAll { $0.id == category.id } } label: { Image(systemName: "trash") }.help(english ? "Delete category" : "카테고리 삭제")
                    }
                    TextField(english ? "Details and checklist" : "세부 작업 · 메모", text: $category.note, axis: .vertical).lineLimit(2...5)
                }.padding(12).background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
            }
            Button { categories.append(StudioCategory()) } label: { Label(english ? "Add subcategory" : "하부 카테고리 추가", systemImage: "plus") }
        }
    }
}
