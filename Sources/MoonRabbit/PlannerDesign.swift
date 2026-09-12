import SwiftUI

extension View {
    func plannerSurface(_ appearance: PetAppearance) -> some View {
        self.background(appearance.plannerCard.color, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(appearance.plannerCard.ink.opacity(0.07)))
            .foregroundStyle(appearance.plannerCard.ink)
    }
}

struct PlannerGoalCard<Footer: View>: View {
    @Environment(\.plannerContentZoom) private var zoom
    let title: String
    let subtitle: String
    let placeholder: String
    @Binding var goal: String
    let appearance: PetAppearance
    @ViewBuilder let footer: () -> Footer
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2).fill(appearance.plannerAccent.color).frame(width: 4, height: 24)
                Text(title).font(.system(size: 20 * zoom, weight: .semibold))
            }
            Text(subtitle).font(.system(size: 12 * zoom)).foregroundStyle(.secondary)
            TextField(placeholder, text: $goal, axis: .vertical)
                .font(.system(size: 25 * zoom, weight: .medium)).lineLimit(2...4)
                .textFieldStyle(.plain).accessibilityLabel(title)
                .padding(.vertical, 6)
            footer().frame(minHeight: 18, alignment: .leading)
        }.padding(22).frame(maxWidth: .infinity, alignment: .leading).plannerSurface(appearance)
    }
}

struct MonthlyGoalCard: View {
    @ObservedObject var state: PetState
    let date: Date
    let role: WorkRole
    var body: some View {
        PlannerGoalCard(title: state.tr("이달의 목표"), subtitle: state.tr("한 달을 이끌어 갈 방향"),
                        placeholder: state.tr("이번 달에 이루고 싶은 일"),
                        goal: Binding(get: { state.plan.monthlyRecords[MonthlyRecord.key(date: date, role: role)]?.goal ?? "" },
                                      set: { state.plan.monthlyRecords[MonthlyRecord.key(date: date, role: role), default: MonthlyRecord()].goal = $0 }),
                        appearance: state.appearance) {
            Text(date, format: .dateTime.year().month(.wide)).font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }
}

struct PlannerNameEditor: View {
    @ObservedObject var state: PetState
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(state.tr("플래너 이름 변경")).font(.system(size: 20, weight: .semibold))
            TextField(state.tr("달토끼 플래너"), text: $state.appearance.plannerTitle, axis: .vertical)
                .font(.system(size: 22, weight: .medium)).lineLimit(1...3).textFieldStyle(.roundedBorder)
                .accessibilityLabel(state.tr("플래너 제목"))
            Text(state.tr("변경 사항은 자동 저장돼요.")).font(.system(size: 12)).foregroundStyle(.secondary)
            HStack {
                Button(state.tr("기본 이름")) { state.appearance.plannerTitle = "" }
                Spacer()
                Button(state.tr("완료")) { dismiss() }.buttonStyle(.borderedProminent)
            }
        }.padding(22).frame(width: 350)
    }
}

extension WorkRole {
    var plannerSymbol: String {
        switch self {
        case .developer: return "chevron.left.forwardslash.chevron.right"
        case .designer: return "pencil.and.outline"
        case .planner: return "list.bullet.rectangle"
        case .soloStartup: return "spark"
        case .student: return "book.closed"
        case .office: return "briefcase"
        case .startupTeam: return "person.2"
        }
    }
}


struct PlannerLogoMenu: View {
    @ObservedObject var state: PetState
    static let options = [
        ("original", "기본 로고", "Original logo", "cup.and.saucer"),
        ("ribbon", "리본", "Ribbon", "gift"),
        ("heart", "하트", "Heart", "heart"),
        ("pencil", "연필", "Pencil", "pencil"),
        ("smile", "스마일", "Smile", "face.smiling"),
        ("rabbit", "토끼 실루엣", "Rabbit silhouette", "hare.fill"),
        ("star", "별", "Star", "star"),
        ("check", "체크 표시", "Checkmark", "checkmark.circle")
    ]
    var selected: String { state.appearance.plannerLogo ?? "original" }
    @State private var showing = false
    var body: some View {
        Button { showing.toggle() } label: {
            Group {
                if selected == "original" {
                    Image(nsImage: PetArtwork.image("plannerLogo")).resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if selected == "ribbon" {
                    Text("🎀").font(.system(size: 30))
                } else {
                    Image(systemName: Self.options.first(where: { $0.0 == selected })?.3 ?? "cup.and.saucer")
                        .font(.system(size: 30, weight: .regular)).foregroundStyle(state.appearance.plannerAccent.color)
                }
            }.frame(width: 52, height: 52).clipped()
        }.buttonStyle(.plain)
            .accessibilityLabel(state.language == .en ? "Change planner logo" : "플래너 로고 변경")
            .help(state.language == .en ? "Choose a logo · saved automatically" : "로고 선택 · 자동 저장")
            .popover(isPresented: $showing) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(state.language == .en ? "Choose your logo" : "로고를 골라주세요").font(.headline)
                    ForEach(Self.options, id: \.0) { option in
                        Button {
                            state.appearance.plannerLogo = option.0
                            showing = false
                        } label: {
                            HStack {
                                Text(state.language == .en ? option.2 : option.1)
                                Spacer()
                                if selected == option.0 { Image(systemName: "checkmark") }
                            }.frame(width: 180).padding(6)
                        }.buttonStyle(.plain)
                    }
                }.padding(18)
            }
    }
}

private struct PlannerContentZoomKey: EnvironmentKey { static let defaultValue: CGFloat = 1 }
extension EnvironmentValues {
    var plannerContentZoom: CGFloat {
        get { self[PlannerContentZoomKey.self] }
        set { self[PlannerContentZoomKey.self] = newValue }
    }
}
