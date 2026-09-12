import SwiftUI


struct DailyPlanView: View {
    @ObservedObject var state: PetState
    var role: WorkRole { state.activeRole }
    @AppStorage("plannerTimeStep") private var savedTimeStep = 10
    var timeStep: Int { PlanningTimeOptions.step(savedTimeStep) }
    @State private var date = Date()
    @State private var showDateChooser = false
    @State private var monthView = false
    @AppStorage("plannerPeriod") private var periodValue = PlannerPeriod.month.rawValue
    @AppStorage("plannerStart") private var startTimestamp = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
    var periodStart: Date { Date(timeIntervalSince1970: startTimestamp) }
    var periodEnd: Date { (PlannerPeriod(rawValue: periodValue) ?? .month).end(start: periodStart) }
    @State private var showAppearance = false
    @State private var showRename = false
    @State private var showAlarms = false
    var plannerInk: Color { state.appearance.plannerCard.ink }
    var plannerSage: Color { state.appearance.plannerAccent.color }
    let save: () -> Void
    let settings: () -> Void
    let toggle: () -> Void
    let focus: (Int) -> Void
    var dayKey: String { DailyPlan.key(for: date) }
    var rows: [PlanItem] { state.plan.modeItems(day: dayKey, role: role) }
    var items: Binding<[PlanItem]> { Binding(get: { rows }, set: { state.plan.setModeItems($0, day: dayKey, role: role) }) }
    var activeRows: [PlanItem] { rows.filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty } }
    var completed: Int { activeRows.filter(\.done).count }
    func deleteTask(_ id: UUID) {
        state.plan.setModeItems(rows.filter { $0.id != id }, day: dayKey, role: role)
        save()
    }
    var todayWork: String {
        let seconds = Int(state.plan.workSeconds[dayKey, default: 0])
        return String(format: "%02d:%02d", seconds / 3600, seconds / 60 % 60)
    }
    @AppStorage("plannerZoom") private var plannerZoom = 1.0
    @State private var measuredHeight: CGFloat = 1000
    var zoom: CGFloat { min(1.4, max(0.75, plannerZoom)) }
    var body: some View {
        GeometryReader { geometry in
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 20) {
                header
                modeSelector
                periodControls
                if monthView {
                    MonthPlannerView(state: state, role: role, date: $date, start: periodStart, end: periodEnd, openDay: { monthView = false }, save: save)
                } else {
                HStack(alignment: .top, spacing: 16) {
                    intention
                    MonthlyGoalCard(state: state, date: date, role: role)
                }
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 16) { taskList; RoleToolsView(state: state, dayKey: dayKey, focus: focus, role: role); notes }
                        .frame(maxWidth: .infinity)
                    VStack(spacing: 14) { milestone; rhythm }.frame(width: 270)
                }
                }
                HStack {
                    Text(state.tr("작은 계획들이 모여 나의 하루가 돼요.")).font(.system(size: 13)).foregroundStyle(.secondary)
                    Spacer()
                    Button(state.tr(state.saved ? "저장됨 ✓" : (monthView ? "월간 저장" : "하루 저장")), action: save)
                        .buttonStyle(.borderedProminent).controlSize(.large)
                }
            }.padding(24)
                .frame(width: max(880, geometry.size.width / zoom))
                .background(GeometryReader { inner in Color.clear.preference(key: PlannerHeightKey.self, value: inner.size.height) })
                .scaleEffect(zoom, anchor: .topLeading)
                .frame(width: max(880, geometry.size.width / zoom) * zoom, height: measuredHeight * zoom, alignment: .topLeading)
        }.onPreferenceChange(PlannerHeightKey.self) { measuredHeight = $0 }
        }.frame(minWidth: 600, idealWidth: 980, minHeight: 440, idealHeight: 780)
            .font(.system(size: 14))
            .background(state.appearance.plannerBackground.color)
            .foregroundStyle(state.appearance.plannerBackground.ink).tint(plannerSage)
            .onAppear { if UserDefaults.standard.object(forKey: "plannerStart") == nil { UserDefaults.standard.set(startTimestamp, forKey: "plannerStart") } }
            .onChange(of: periodValue) { _ in date = min(max(date, periodStart), periodEnd) }
            .onChange(of: startTimestamp) { _ in date = min(max(date, periodStart), periodEnd) }
            .environment(\.locale, Locale(identifier: state.language == .ko ? "ko_KR" : "en_US"))
    }
    var periodControls: some View {
        VStack(spacing: 8) {
            HStack {
                Button { monthView = false } label: { Label(state.tr("일간"), systemImage: "chevron.left") }.disabled(!monthView)
                Text(state.tr(monthView ? "월간 플래너" : "일간 플래너")).font(.headline)
                Button { monthView = true; date = min(max(date, periodStart), periodEnd) } label: { Label(state.tr("월간"), systemImage: "chevron.right") }.disabled(monthView)
                Spacer()
                Picker(state.tr("계획 기간"), selection: $periodValue) {
                    ForEach(PlannerPeriod.allCases, id: \.rawValue) { Text(state.tr($0.title)).tag($0.rawValue) }
                }.frame(width: 155)
            }
            HStack {
                DatePicker(state.tr("시작일"), selection: Binding(get: { periodStart }, set: { startTimestamp = Calendar.current.startOfDay(for: $0).timeIntervalSince1970 }), displayedComponents: .date)
                Text("→")
                Text(periodEnd, format: .dateTime.year().month().day())
                Spacer()
            }.font(.caption)
        }.padding(.horizontal, 4)
    }
    func addTask(_ item: PlanItem) { state.plan.setModeItems(rows + [item], day: dayKey, role: role) }
    var modeSelector: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(state.tr("플래너 모드")).font(.system(size: 19, weight: .semibold))
                Spacer()
                Text(state.tr("모드별 일정과 노트는 따로 보관돼요.")).font(.system(size: 12)).foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 8)], spacing: 8) {
                ForEach(WorkRole.allCases, id: \.rawValue) { option in
                    Button { state.roleValue = option.rawValue } label: {
                        HStack(spacing: 8) {
                            Image(systemName: option.plannerSymbol).frame(width: 18)
                            Text(state.tr(option.title)).font(.system(size: 14, weight: .medium))
                            Spacer(minLength: 0)
                            if option == role { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)) }
                        }.padding(.horizontal, 12).frame(height: 42)
                            .foregroundStyle(option == role ? state.appearance.plannerAccent.ink : plannerInk)
                            .background(option == role ? plannerSage : plannerInk.opacity(0.04), in: RoundedRectangle(cornerRadius: 9))
                    }.buttonStyle(.plain)
                        .accessibilityAddTraits(option == role ? .isSelected : [])
                }
            }
            if role == .startupTeam {
                Text(state.tr("이 Mac에서 팀 업무를 정리하는 모드입니다. 실시간 공동 편집은 지원하지 않습니다.")).font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }.padding(20).plannerSurface(state.appearance)
    }
    @State private var showMealRoulette = false
    var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                PlannerLogoMenu(state: state)
                Text(state.appearance.resolvedPlannerTitle(language: state.language))
                    .font(.system(size: 30, weight: .semibold)).lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Button { showRename = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel(state.tr("플래너 이름 변경"))
                    .help(state.tr("플래너 이름 변경"))
                    .popover(isPresented: $showRename) { PlannerNameEditor(state: state) }
                Spacer(minLength: 8)
                Menu {
                    ForEach([75, 90, 100, 110, 125, 140], id: \.self) { value in
                        Button("\(value)%") { plannerZoom = Double(value) / 100 }
                    }
                } label: { Text("\(Int(zoom * 100))%") }
                    .accessibilityLabel(state.language == .ko ? "플래너 확대 축소" : "Planner zoom")
                Button { showAppearance.toggle() } label: { Image(systemName: "paintpalette") }
                    .help(state.tr("문구와 색상 꾸미기")).accessibilityLabel(state.tr("문구와 색상 꾸미기"))
                    .popover(isPresented: $showAppearance) { AppearanceView(state: state, save: save) }
                Button { showMealRoulette.toggle() } label: { Image(systemName: "fork.knife") }
                    .accessibilityLabel(state.language == .ko ? "메뉴 룰렛" : "Meal roulette")
                    .popover(isPresented: $showMealRoulette) { MealRouletteView(state: state) }
                Button { showAlarms.toggle() } label: { Image(systemName: "alarm") }
                    .accessibilityLabel(state.tr("알람"))
                    .popover(isPresented: $showAlarms) { AlarmSettingsView(state: state) }
                Button(action: settings) { Image(systemName: "slider.horizontal.3") }
                    .accessibilityLabel(state.tr("설정"))
            }.font(.system(size: 17)).buttonStyle(.borderless)
            HStack(spacing: 14) {
                Button { date = Calendar.current.date(byAdding: .day, value: -1, to: date)! } label: { Image(systemName: "chevron.left") }.accessibilityLabel(state.tr("이전 날"))
                Button { showDateChooser.toggle() } label: {
                    Text(date, format: .dateTime.year().month().day()).font(.system(size: 23, weight: .semibold))
                }.buttonStyle(.plain).accessibilityLabel(state.language == .ko ? "날짜 변경" : "Change date")
                    .popover(isPresented: $showDateChooser) {
                        DatePicker(state.language == .ko ? "날짜" : "Date", selection: $date, displayedComponents: .date).padding(20)
                    }
                Button { date = Calendar.current.date(byAdding: .day, value: 1, to: date)! } label: { Image(systemName: "chevron.right") }.accessibilityLabel(state.tr("다음 날"))
                Button(state.tr("오늘")) { date = Date() }
                Spacer()
                Text(date, format: .dateTime.weekday(.wide)).font(.system(size: 20, weight: .medium)).foregroundStyle(.secondary)
            }.buttonStyle(.borderless)
            Divider().overlay(plannerSage.opacity(0.25))
        }
    }
    var intention: some View {
        PlannerGoalCard(title: state.tr("오늘의 목표"), subtitle: state.tr("오늘 가장 중요한 한 가지"),
                        placeholder: state.tr("오늘의 목표를 적어주세요"), goal: $state.goal,
                        appearance: state.appearance) {
            Toggle(state.tr("말풍선에 목표 표시"), isOn: $state.showGoal).font(.system(size: 12)).toggleStyle(.checkbox)
        }
    }
    var taskList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(state.tr(role.taskHeading)).font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(completed) / \(activeRows.count)").font(.system(size: 13, design: .monospaced)).foregroundStyle(.secondary)
                Button { addTask(PlanItem()) } label: { Image(systemName: "plus.circle.fill") }.buttonStyle(.plain).accessibilityLabel(state.tr("+ 일정 추가"))
            }
            HStack {
                Text(state.tr("시간 선택 간격")).font(.system(size: 12))
                Picker(state.tr("시간 선택 간격"), selection: $savedTimeStep) {
                    Text(state.tr("10분 단위")).tag(10)
                    Text(state.tr("30분 단위")).tag(30)
                }.pickerStyle(.segmented).labelsHidden().frame(width: 160)
                Spacer()
            }
            ProgressView(value: Double(completed), total: Double(max(1, activeRows.count))).tint(plannerSage)
            HStack(spacing: 6) {
                Text(state.tr("색상")).frame(width: 28)
                Text(state.tr("시간")).frame(width: 76)
                Text(state.tr(role.categoryTitle)).frame(width: 74)
                Text(state.tr("할 일")).frame(maxWidth: .infinity, alignment: .leading)
                Text(state.tr("분")).frame(width: 82)
                Text("✓").frame(width: 28)
            }.font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            ScrollView {
                VStack(spacing: 8) {
                    if items.wrappedValue.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "leaf").font(.system(size: 24)).foregroundStyle(plannerSage)
                            Text(state.tr("아직 비어 있는 하루, 첫 계획을 적어봐요.")).font(.system(size: 14)).foregroundStyle(.secondary)
                            Button(state.tr("+ 일정 추가")) { addTask(PlanItem()) }
                        }.frame(maxWidth: .infinity).padding(.vertical, 25)
                    }
                    ForEach(items) { $item in
                        HStack(spacing: 6) {
                            ColorPicker("", selection: Binding(get: { (item.color ?? state.appearance.plannerAccent).color }, set: { item.color = PetColor($0) }), supportsOpacity: false)
                                .labelsHidden().frame(width: 28).accessibilityLabel(state.tr("일정 색상"))
                            ScrollTimePicker(title: state.tr("시작 시각"), display: item.time.isEmpty ? "--:--" : item.time,
                                             options: PlanningTimeOptions.starts(step: timeStep), selected: item.startMinute,
                                             label: PlanningTimeOptions.clock) { item.time = PlanningTimeOptions.clock($0) }
                                .frame(width: 76)
                            TextField(state.tr(role.categoryTitle), text: $item.category).frame(width: 74).accessibilityLabel(state.tr("분류"))
                            TextField(state.tr("할 일"), text: $item.title).strikethrough(item.done).accessibilityLabel(state.tr("할 일"))
                            ScrollTimePicker(title: state.tr("예정 분량"), display: "\(item.minutes)",
                                             options: PlanningTimeOptions.durations(step: timeStep), selected: item.minutes,
                                             label: { "\($0) \(state.tr("분"))" }) { item.minutes = $0 }
                                .frame(width: 82)
                            Toggle("", isOn: $item.done).labelsHidden().frame(width: 28).accessibilityLabel(state.tr("완료"))
                        }.textFieldStyle(.roundedBorder).font(.system(size: 13)).padding(.vertical, 5)
                        HStack {
                            Picker(state.tr("우선순위"), selection: $item.priority) {
                                Text(state.tr("보통")).tag("normal")
                                Text(state.tr("높음")).tag("high")
                                Text(state.tr("낮음")).tag("low")
                            }.frame(width: 135)
                            if role.usesOwner {
                                TextField(state.tr("담당자"), text: $item.owner).textFieldStyle(.roundedBorder)
                            }
                            Spacer(minLength: 0)
                            Button(role: .destructive) { deleteTask(item.id) } label: {
                                Label(state.tr("일정 삭제"), systemImage: "trash")
                            }.buttonStyle(.bordered).controlSize(.regular)
                        }.font(.system(size: 12))
                        Divider().opacity(0.5)
                    }
                }
            }.frame(height: 250)
        }.padding(20).plannerSurface(state.appearance)
    }
    var notes: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(state.tr("기억하고 싶은 메모")).font(.system(size: 14, weight: .semibold))
            TextEditor(text: Binding(get: { state.plan.notes[dayKey, default: ""] }, set: { state.plan.notes[dayKey] = $0 }))
                .font(.system(size: 14)).scrollContentBackground(.hidden).frame(height: 65)
                .accessibilityLabel(state.tr("하루 메모"))
        }.padding(20).plannerSurface(state.appearance)
    }
    var milestone: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(state.appearance.milestoneHeading.isEmpty ? state.tr("기다리는 그날") : state.appearance.milestoneHeading).font(.system(size: 13, weight: .semibold))
                Spacer()
                Toggle("", isOn: $state.showDDay).labelsHidden().toggleStyle(.switch).controlSize(.mini).accessibilityLabel(state.tr("말풍선에 디데이 표시"))
            }
            HStack(alignment: .firstTextBaseline) {
                Text(state.appearance.dayLabel(target: state.ddayDate)).font(.system(size: 30, weight: .medium, design: .rounded)).monospacedDigit().lineLimit(2).minimumScaleFactor(0.6)
                Spacer()
                Image(systemName: "moon.stars").font(.system(size: 22))
            }
            TextField(state.tr("기념일이나 마감 이름"), text: $state.ddayTitle).textFieldStyle(.plain).font(.system(size: 14))
            DatePicker("", selection: $state.ddayDate, displayedComponents: .date).labelsHidden()
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(state.tr("이날 집중한 시간")).font(.system(size: 12))
                    Text(todayWork).font(.system(size: 21, design: .monospaced))
                }
                Spacer()
                Button(state.tr(state.running ? "일시정지" : "시작"), action: toggle).buttonStyle(.bordered)
            }
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(state.appearance.plannerCard.color, in: RoundedRectangle(cornerRadius: 16)).foregroundStyle(plannerInk)
    }
    func scheduleHint(minute: Int) -> String {
        let matches = rows.filter { $0.overlapsBlock(start: minute, length: timeStep) }
        return ([PlanningTimeOptions.clock(minute)] + matches.map { "\($0.title) · \(state.tr("우선순위")): \(state.tr($0.priorityLabel))" }).joined(separator: "\n")
    }
    func scheduleColor(minute: Int) -> Color {
        guard let row = rows.first(where: { $0.overlapsBlock(start: minute, length: timeStep) }) else { return plannerInk.opacity(0.055) }
        return (row.color ?? state.appearance.plannerAccent).color
    }
    var rhythm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(state.tr("하루 일정")).font(.system(size: 13, weight: .semibold))
            Text(state.tr(timeStep == 30 ? "30분 칸 · 눌러서 일정 추가" : "10분 칸 · 눌러서 일정 추가")).font(.system(size: 12)).foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Text(state.tr("시간")).frame(width: 26)
                ForEach(0..<(60 / timeStep), id: \.self) { part in
                    Text("\(String(format: "%02d", part * timeStep))\(state.tr("분"))")
                        .frame(maxWidth: .infinity).minimumScaleFactor(0.7).lineLimit(1)
                }
            }.font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
            VStack(spacing: 5) {
                ForEach(0..<24, id: \.self) { hour in
                    HStack(spacing: 4) {
                        Button(String(format: "%02d", hour)) {
                            addTask(PlanItem(time: String(format: "%02d:00", hour)))
                        }.buttonStyle(.plain).font(.system(size: 12, design: .monospaced)).frame(width: 26)
                        ForEach(0..<(60 / timeStep), id: \.self) { part in
                            let minute = hour * 60 + part * timeStep
                            Button {
                                addTask(PlanItem(time: PlanningTimeOptions.clock(minute), minutes: timeStep))
                            } label: {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(scheduleColor(minute: minute))
                                    .frame(height: 15)
                            }.buttonStyle(.plain).help(scheduleHint(minute: minute))
                                .accessibilityLabel("\(PlanningTimeOptions.clock(minute)) · \(state.tr("+ 일정 추가"))")
                                .contextMenu {
                                    ForEach(rows.filter { $0.overlapsBlock(start: minute, length: timeStep) }) { row in
                                        Button(role: .destructive) { deleteTask(row.id) } label: {
                                            Label("\(state.tr("일정 삭제")): \(row.title.isEmpty ? row.time : row.title)", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                    }
                }
            }
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(state.appearance.plannerCard.color, in: RoundedRectangle(cornerRadius: 16)).foregroundStyle(plannerInk)
    }
}

struct WeatherView: View {
    @ObservedObject var state: PetState
    @ObservedObject var weather: WeatherModel
    let report: (WeatherPlace, CurrentWeather) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text(state.tr("날씨")).font(.headline); Spacer(); if weather.loading { ProgressView().controlSize(.small) } }
            HStack {
                TextField(state.tr("도시·동네 (예: 서울 연남동)"), text: $weather.query).textFieldStyle(.roundedBorder)
                    .onSubmit { weather.search(language: state.language) }
                Button(state.tr("검색")) { weather.search(language: state.language) }.disabled(weather.loading)
            }
            Text(state.tr("예: 서울 연남동 · 부산 우동 · 제주 애월읍")).font(.caption2).foregroundStyle(.secondary)
            if !weather.status.isEmpty { Text(state.tr(weather.status)).font(.caption).foregroundStyle(.secondary) }
            ScrollView { VStack(spacing: 5) { ForEach(weather.places) { place in
                Button { weather.fetch(place, report: report) } label: {
                    Text(place.label).font(.system(size: 12)).multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(.bordered)
            }
            } }.frame(maxHeight: weather.places.isEmpty ? 0 : 115)
            if let place = weather.selected {
                HStack {
                    Text(place.label).font(.caption).lineLimit(2)
                    Spacer()
                    Button(state.tr("새로고침")) { weather.fetch(place, report: report) }.disabled(weather.loading)
                }
            }
            if let current = weather.current {
                HStack {
                    Text(String(format: "%.1f°C", current.temperature_2m)).font(.system(size: 30, weight: .light))
                    Spacer()
                    Text(state.tr(current.descriptionKey)).font(.headline)
                }
                Text("\(state.tr("체감")) \(String(format: "%.1f", current.apparent_temperature))°C · \(state.tr("바람")) \(String(format: "%.1f", current.wind_speed_10m)) km/h").font(.caption)
                Text("\(state.tr("현지 시각")) \(current.time.replacingOccurrences(of: "T", with: " "))").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(state.tr("날씨를 열거나 검색·새로고침할 때 인터넷을 사용해요.")).font(.caption2).foregroundStyle(.secondary)
            Link("Weather: Open-Meteo", destination: URL(string: "https://open-meteo.com/")!).font(.caption2)
            Link("Search: Photon · © OpenStreetMap contributors", destination: URL(string: "https://www.openstreetmap.org/copyright")!).font(.caption2)
        }.padding(16).frame(width: 350, height: 410).tint(.brown)
            .background(Color(red: 0.97, green: 0.94, blue: 0.90))
    }
}

private struct PlannerHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 1000
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
