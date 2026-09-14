import AppKit
import SwiftUI
import Combine

enum PetArtwork {
    static let bundle: Bundle = {
        let packaged = Bundle.main.resourceURL?.appendingPathComponent("MoonRabbit_MoonRabbit.bundle")
        return packaged.flatMap { Bundle(url: $0) } ?? Bundle.module
    }()
    static var images: [String: NSImage] = [:]
    static func image(_ name: String) -> NSImage {
        if let cached = images[name] { return cached }
        guard let url = bundle.url(forResource: name, withExtension: "png"), let image = NSImage(contentsOf: url) else {
            if name != "rabbit" { return self.image("rabbit") }
            fatalError("Missing rabbit.png in app resources")
        }
        images[name] = image
        return image
    }
}

final class PetAnimationState: ObservableObject {
    @Published var blinking = false
    @Published var phase = 0.0
    @Published var gait = 0.0
    @Published var walkDistance = 0.0
    @Published var facing = 1.0
}

final class PetState: ObservableObject {
    @Published var alarms: [RabbitAlarm] = {
        guard let data = UserDefaults.standard.data(forKey: "rabbitAlarms") else { return [] }
        return (try? JSONDecoder().decode([RabbitAlarm].self, from: data)) ?? []
    }() {
        didSet { if let data = try? JSONEncoder().encode(alarms) { UserDefaults.standard.set(data, forKey: "rabbitAlarms") } }
    }
    @Published var appearance: PetAppearance = {
        guard let data = UserDefaults.standard.data(forKey: "appearance"),
              var value = try? JSONDecoder().decode(PetAppearance.self, from: data) else { return PetAppearance() }
        value.updateLegacyPlannerPalette()
        return value
    }() {
        didSet { saveAppearance() }
    }
    func saveAppearance() {
        if let data = try? JSONEncoder().encode(appearance) { UserDefaults.standard.set(data, forKey: "appearance") }
    }
    @Published var roleValue = UserDefaults.standard.string(forKey: "workRole") ?? "developer" {
        didSet { UserDefaults.standard.set(roleValue, forKey: "workRole") }
    }
    var activeRole: WorkRole { WorkRole(rawValue: roleValue) ?? .developer }
    let animation = PetAnimationState()
    @Published var showDDay = UserDefaults.standard.bool(forKey: "showDDayInBubble")
    @Published var ddayTitle = UserDefaults.standard.string(forKey: "ddayTitle") ?? ""
    @Published var ddayDate = UserDefaults.standard.object(forKey: "ddayDate") as? Date ?? Date()
    func saveMilestone() {
        UserDefaults.standard.set(showDDay, forKey: "showDDayInBubble")
        UserDefaults.standard.set(ddayTitle, forKey: "ddayTitle")
        UserDefaults.standard.set(ddayDate, forKey: "ddayDate")
    }
    @Published var language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "language") ?? "ko") ?? .ko
    func tr(_ korean: String) -> String { PetStrings.text(korean, language: language) }
    @Published var hovering = false
    var activityStart = 0.0
    @Published var time = "00:00:00"
    @Published var timerMode = TimerMode(rawValue: UserDefaults.standard.string(forKey: "timerMode") ?? "stopwatch") ?? .stopwatch
    @Published var minutes = UserDefaults.standard.object(forKey: "timerMinutes") as? Int ?? 25
    @Published var countdown = FocusTimer(seconds: UserDefaults.standard.object(forKey: "remainingSeconds") as? Double ?? 1500)
    @Published var showGoal = UserDefaults.standard.object(forKey: "showGoalInBubble") as? Bool ?? false
    @Published var saved = false
    @Published var plan: DailyPlan = {
        guard let data = UserDefaults.standard.data(forKey: "dailyPlan") else { return DailyPlan() }
        var plan = (try? JSONDecoder().decode(DailyPlan.self, from: data)) ?? DailyPlan()
        if plan.legacyRole == nil { plan.legacyRole = UserDefaults.standard.string(forKey: "workRole") ?? "developer" }
        return plan
    }()
    @Published var goal = UserDefaults.standard.string(forKey: "workGoal") ?? ""
    var timerDisplay: String { timerMode == .countdown ? countdown.display : time }
    @Published var running = false
    @Published var message = "안녕! 오늘도 곁에 있을게요 🌸"
    @Published var weatherAttribution = false
    @Published var activity: PetActivity = .idle
    @Published var wandering = UserDefaults.standard.object(forKey: "wandering") as? Bool ?? true
    @Published var scale = min(1.6, max(0.6, UserDefaults.standard.object(forKey: "petScale") as? Double ?? 1))
    @Published var visible = true
    var clock = WorkClock(elapsed: UserDefaults.standard.double(forKey: "workSeconds"))
    var messageUntil = Date().addingTimeInterval(8)
    func say(_ text: String, duration: Double = 7) { weatherAttribution = false; message = text; messageUntil = Date().addingTimeInterval(duration) }
}

final class PetPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class DragSurface: NSView {
    var dragOffset: NSPoint?
    var didDrag = false
    var onPet: (() -> Void)?
    var onMenu: (() -> Void)?
    var onHover: ((Bool) -> Void)?
    private var hoverArea: NSTrackingArea?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverArea { removeTrackingArea(hoverArea) }
        let area = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(area); hoverArea = area
    }
    override func mouseEntered(with event: NSEvent) { onHover?(true) }
    override func mouseExited(with event: NSEvent) { onHover?(false) }
    override func rightMouseDown(with event: NSEvent) { onMenu?() }
    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        let mouse = NSEvent.mouseLocation
        dragOffset = NSPoint(x: mouse.x - window.frame.minX, y: mouse.y - window.frame.minY)
        didDrag = false
    }
    override func mouseDragged(with event: NSEvent) {
        guard let window, let offset = dragOffset else { return }
        didDrag = true
        window.setFrameOrigin(NSPoint(x: NSEvent.mouseLocation.x - offset.x, y: NSEvent.mouseLocation.y - offset.y))
    }
    override func mouseUp(with event: NSEvent) { if !didDrag { onPet?() }; dragOffset = nil }
}
struct PetTouch: NSViewRepresentable {
    let onPet: () -> Void
    let onMenu: () -> Void
    let onHover: (Bool) -> Void
    func makeNSView(context: Context) -> DragSurface { let v = DragSurface(); v.onPet = onPet; v.onMenu = onMenu; v.onHover = onHover; return v }
    func updateNSView(_ nsView: DragSurface, context: Context) {}
}

struct PetView: View {
    @ObservedObject var state: PetState
    @ObservedObject var animation: PetAnimationState
    init(state: PetState, pet: @escaping () -> Void, menu: @escaping () -> Void, hover: @escaping (Bool) -> Void) {
        self.state = state; self.animation = state.animation; self.pet = pet; self.menu = menu; self.hover = hover
    }
    let pet: () -> Void
    let menu: () -> Void
    let hover: (Bool) -> Void
    var localPhase: Double { state.animation.phase - state.activityStart }
    var artwork: String {
        switch state.activity {
        case .work: return state.activeRole.workArtwork + "\(Int(localPhase * 1.4) % 2)"
        case .walk: return localPhase < 0.28 ? "turnThreeQuarter" : "walkCycle\(WalkCycle.frame(distance: state.animation.walkDistance))"
        case .snack: return Int(localPhase * 2.5) % 2 == 0 ? "snack" : "snackB"
        case .dance: return Int(localPhase * 2.5) % 2 == 0 ? "dance" : "danceB"
        case .stretch: return Int(localPhase * 0.7) % 2 == 0 ? "stretch" : "stretchB"
        case .coffee: return Int(localPhase * 0.7) % 2 == 0 ? "coffee" : "coffeeB"
        case .flower: return Int(localPhase * 0.6) % 2 == 0 ? "flower" : "flowerB"
        case .idle: return state.animation.blinking ? "blink" : "rabbit"
        case .smile: return "smile"
        }
    }
    var rotation: Double {
        switch state.activity {
        case .dance: return sin(state.animation.phase * 5) * 11
        case .smile: return sin(state.animation.phase * 2.5) * 4
        case .snack: return sin(state.animation.phase * 4) * 1.6
        case .walk: return sin(state.animation.walkDistance / 32 * .pi * 2) * 0.7 * state.animation.gait
        case .idle: return sin(state.animation.phase * 1.2) * 0.6
        case .stretch: return sin(localPhase * 1.8) * 2
        case .work: return sin(localPhase * 1.8) * 0.3
        case .coffee: return sin(localPhase * 1.8) * 1.2
        case .flower: return sin(localPhase * 2) * 2
        }
    }
    var lift: Double {
        switch state.activity {
        case .dance: return abs(sin(state.animation.phase * 5)) * 15
        case .smile: return abs(sin(state.animation.phase * 2.5)) * 3
        case .snack: return (1 + sin(state.animation.phase * 7)) * 0.7
        case .walk: return abs(sin(state.animation.walkDistance / 32 * .pi * 2)) * 1.2 * state.animation.gait
        case .idle: return (1 + sin(state.animation.phase * 1.8)) * 0.5
        case .stretch: return (1 + sin(localPhase * 1.8)) * 2
        case .work: return (1 + sin(localPhase * 1.8)) * 0.3
        case .coffee: return (1 + sin(localPhase * 1.8)) * 0.6
        case .flower: return 0
        }
    }
    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    if state.showDDay {
                        Text(state.appearance.dayLabel(target: state.ddayDate)).font(.system(size: 12, weight: .bold, design: .rounded))
                        Text(state.ddayTitle).font(.system(size: 10)).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Text(state.timerDisplay).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
                }
                if state.showGoal && !state.goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("🎯 \(state.goal)").font(.system(size: 11, weight: .semibold)).lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Divider().overlay(Color.brown.opacity(0.15))
                Text(state.message.isEmpty ? state.tr("곁에서 응원하고 있어요 🌿") : state.message).lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if state.weatherAttribution {
                    Link("Open-Meteo · CC BY 4.0", destination: URL(string: "https://open-meteo.com/")!)
                        .font(.system(size: 9)).foregroundStyle(state.appearance.bubbleBackground.ink)
                }
            }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(state.appearance.bubbleBackground.ink)
                .multilineTextAlignment(.center).padding(.horizontal, 13).padding(.vertical, 10)
                .frame(maxWidth: 218, minHeight: 52)
                .background(RoundedRectangle(cornerRadius: 17).fill(state.appearance.bubbleBackground.color))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(state.appearance.bubbleBorder.color, lineWidth: 1))
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
            ZStack {
                Image(nsImage: PetArtwork.image(artwork)).resizable().interpolation(.high).scaledToFit()
                    .frame(width: 180, height: 235)
                    .id(artwork).transition(.opacity)
                    .animation(state.activity == .walk ? nil : .easeInOut(duration: state.animation.blinking ? 0.04 : 0.18), value: artwork)
                    .scaleEffect(x: 1 + (state.activity == .dance ? sin(state.animation.phase * 5) * 0.015 : 0),
                                 y: 1 + sin(state.animation.phase * (state.activity == .snack ? 7 : 1.8)) * 0.008,
                                 anchor: .bottom)
                    .scaleEffect(x: state.activity == .walk ? state.animation.facing : 1, y: 1)
                    .animation(nil, value: state.animation.facing)
                    .rotationEffect(.degrees(rotation), anchor: .bottom)
                    .offset(x: state.activity == .dance ? sin(state.animation.phase * 2.5) * 6 : state.animation.facing * state.animation.gait * 2, y: -lift)
                if state.activity == .dance {
                    Text("♪").font(.system(size: 24)).foregroundStyle(Color.pink.opacity(0.7))
                        .offset(x: 84, y: -65 - sin(state.animation.phase * 3) * 8)
                    Text("♫").font(.system(size: 18)).foregroundStyle(Color.brown.opacity(0.6))
                        .offset(x: -85, y: -12 - cos(state.animation.phase * 3) * 9)
                }
                if state.activity == .smile {
                    Text("♡").font(.system(size: 22)).foregroundStyle(Color.pink.opacity(0.7))
                        .offset(x: 82, y: -65 - sin(state.animation.phase * 2) * 5)
                }
            }.frame(width: 240, height: 250)
                .overlay(PetTouch(onPet: pet, onMenu: menu, onHover: hover))
        }.frame(width: 250, height: 380)
            .scaleEffect(state.scale)
            .frame(width: 250 * state.scale, height: 380 * state.scale)
    }
}

struct ControlView: View {
    @ObservedObject var state: PetState
    let toggle: () -> Void
    let reset: () -> Void
    let perform: (PetActivity) -> Void
    let hide: () -> Void
    let save: () -> Void
    let planner: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(state.tr("☾ 달토끼")).font(.system(size: 16, weight: .semibold))
                Spacer()
                Text(state.tr(state.running ? "집중 중" : "쉬는 중")).font(.system(size: 10)).foregroundStyle(SettingsTheme.secondary)
            }
            TextField(state.tr("오늘의 목표를 적어주세요"), text: $state.goal)
                .textFieldStyle(.roundedBorder).font(.system(size: 12))
                .accessibilityLabel(state.tr("오늘의 목표"))
            HStack {
                Toggle(state.tr("말풍선에 목표 표시"), isOn: $state.showGoal).font(.system(size: 10)).toggleStyle(.checkbox)
                Spacer()
                Button(state.tr("하루 플래너"), action: planner).font(.system(size: 10))
            }
            Picker(state.tr("타이머 방식"), selection: $state.timerMode) {
                Text(state.tr("작업 시간")).tag(TimerMode.stopwatch)
                Text(state.tr("카운트다운")).tag(TimerMode.countdown)
            }.pickerStyle(.segmented)
            HStack(alignment: .center) {
                Text(state.timerDisplay).font(.system(size: 29, weight: .light, design: .monospaced)).monospacedDigit()
                Spacer()
                Button(state.tr(state.running ? "일시정지" : "시작"), action: toggle)
                    .buttonStyle(SettingsActionButtonStyle())
            }
            HStack(spacing: 6) {
                Text(state.tr("설정")).foregroundStyle(SettingsTheme.secondary)
                TextField(state.tr("분"), value: $state.minutes, format: .number)
                    .textFieldStyle(.roundedBorder).frame(width: 46).accessibilityLabel(state.tr("타이머 시간 분"))
                Text(state.tr("분"))
                Spacer()
                Button(state.tr("25분")) { state.minutes = 25; state.timerMode = .countdown; state.countdown = FocusTimer(seconds: 1500) }
                Button(state.tr("50분")) { state.minutes = 50; state.timerMode = .countdown; state.countdown = FocusTimer(seconds: 3000) }
            }.font(.system(size: 11)).disabled(state.running || state.timerMode == .stopwatch)
            HStack {
                Text("\(state.tr("누적")) \(state.time)").foregroundStyle(SettingsTheme.secondary)
                Spacer()
                Button(state.tr("초기화"), action: reset).buttonStyle(.plain)
            }.font(.system(size: 10))
            Divider()
            HStack(spacing: 6) {
                Button(state.tr("🥕 간식")) { perform(.snack) }
                Button(state.tr("♡ 웃기")) { perform(.smile) }
                Button(state.tr("♫ 춤")) { perform(.dance) }
            }.buttonStyle(.bordered).controlSize(.small)
            HStack(spacing: 6) {
                Button(state.tr("↟ 스트레칭")) { perform(.stretch) }
                Button(state.tr("❀ 꽃 주기")) { perform(.flower) }
                Button(state.tr("☕ 커피")) { perform(.coffee) }
            }.buttonStyle(.bordered).controlSize(.small)
            Picker(state.tr("이동"), selection: $state.wandering) {
                Text(state.tr("산책하기")).tag(true)
                Text(state.tr("한자리에 있기")).tag(false)
            }.pickerStyle(.segmented)
            HStack(spacing: 8) {
                Text(state.tr("크기")).font(.system(size: 11))
                Slider(value: $state.scale, in: 0.6...1.6, step: 0.05).accessibilityLabel(state.tr("토끼 크기"))
                Text("\(Int(state.scale * 100))%").font(.system(size: 10)).monospacedDigit().frame(width: 34)
            }
            Text(state.tr("왼쪽 클릭: 빠른 메뉴 · 오른쪽 클릭: 설정"))
                .font(.system(size: 11)).foregroundStyle(SettingsTheme.secondary)
            HStack {
                Text(state.tr("언어"))
                Spacer()
                Picker("Language", selection: $state.language) {
                    Text("한국어").tag(AppLanguage.ko)
                    Text("English").tag(AppLanguage.en)
                }.labelsHidden().frame(width: 105)
            }.font(.system(size: 10))
            HStack {
                Button(state.tr(state.visible ? "펫 숨기기" : "펫 보이기"), action: hide)
                Spacer()
                Button(state.tr(state.saved ? "저장됨 ✓" : "저장"), action: save).buttonStyle(SettingsActionButtonStyle())
                Button(state.tr("종료")) { NSApp.terminate(nil) }
            }.buttonStyle(.plain).font(.system(size: 12))
        }.padding(16).frame(width: 300)
            .settingsSurface()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = PetState()
    var panel: PetPanel!
    var item: NSStatusItem!
    let settings = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 300, height: 410),
                           styleMask: [.titled, .closable, .utilityWindow], backing: .buffered, defer: false)
    var plannerPanel: NSPanel?
    var weatherPanel: NSPanel?
    @MainActor lazy var weather = WeatherModel()
    var actionMenuOpen = false
    var dailyWorkPending: [String: Double] = [:]
    var focusPending = 0.0
    var timer: Timer?
    var lastFrame = ProcessInfo.processInfo.systemUptime
    var motion = WanderMotion()
    var resumeDialogueAfterWeather = false
    var targetX: Double?
    var nextWalk = Date().addingTimeInterval(3)
    var dialogue = PetDialogue()
    var subscriptions = Set<AnyCancellable>()
    var frameCount = 0
    var playUntil = Date.distantPast
    var nextPlay = Date().addingTimeInterval(20)
    var nextBlink = Date().addingTimeInterval(3)
    var blinkUntil = Date.distantPast
    var lastHover = Date.distantPast
    var importantMessageUntil = Date.distantPast
    var didPlaceSettings = UserDefaults.standard.string(forKey: "NSWindow Frame MoonRabbitSettings") != nil
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Relaunching an updated build replaces the previous instance.
        if let identifier = Bundle.main.bundleIdentifier {
            for previous in NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
                where previous.processIdentifier != ProcessInfo.processInfo.processIdentifier {
                previous.terminate()
            }
        }
        NSApp.setActivationPolicy(.accessory)
        panel = PetPanel(contentRect: NSRect(x: 0, y: 0, width: 250, height: 380), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.backgroundColor = .clear; panel.isOpaque = false; panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: PetView(state: state, pet: { [weak self] in self?.showPetMenu() }, menu: { [weak self] in self?.showControls() }, hover: { [weak self] inside in self?.hover(inside) }))
        relocate()
        panel.orderFrontRegardless()
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "☾ 00:00"
        item.button?.target = self; item.button?.action = #selector(showPlanner)
        settings.title = state.tr("달토끼 설정")
        settings.isReleasedWhenClosed = false
        settings.level = .floating
        settings.hidesOnDeactivate = false
        settings.isMovable = true
        settings.isMovableByWindowBackground = true
        settings.setFrameAutosaveName("MoonRabbitSettings")
        settings.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        settings.contentView = NSHostingView(rootView: ControlView(state: state, toggle: { [weak self] in self?.toggle() }, reset: { [weak self] in self?.reset() }, perform: { [weak self] activity in self?.perform(activity) }, hide: { [weak self] in self?.toggleVisibility() }, save: { [weak self] in self?.saveSettings() }, planner: { [weak self] in self?.showPlanner() }))
        settings.setContentSize(settings.contentView!.fittingSize)
        state.$scale.removeDuplicates().sink { [weak self] scale in
            self?.resize(scale)
            UserDefaults.standard.set(scale, forKey: "petScale")
        }.store(in: &subscriptions)
        state.$roleValue.dropFirst().removeDuplicates().sink { [weak self] _ in
            DispatchQueue.main.async { self?.perform(.work) }
        }.store(in: &subscriptions)
        state.$wandering.removeDuplicates().sink { [weak self] enabled in
            self?.motion.stop(); self?.targetX = nil
            self?.nextWalk = Date().addingTimeInterval(1)
            UserDefaults.standard.set(enabled, forKey: "wandering")
        }.store(in: &subscriptions)
        state.$language.removeDuplicates().sink { [weak self] language in
            guard let self else { return }
            UserDefaults.standard.set(language.rawValue, forKey: "language")
            self.settings.title = PetStrings.text("달토끼 설정", language: language)
            self.plannerPanel?.title = PetStrings.text("하루 플래너", language: language)
            self.weatherPanel?.title = PetStrings.text("날씨", language: language)
            self.state.say(PetStrings.text("안녕! 오늘도 곁에 있을게요 🌸", language: language))
        }.store(in: &subscriptions)
        state.$showGoal.removeDuplicates().sink { value in
            UserDefaults.standard.set(value, forKey: "showGoalInBubble")
        }.store(in: &subscriptions)
        state.$goal.removeDuplicates().sink { goal in
            UserDefaults.standard.set(String(goal.prefix(200)), forKey: "workGoal")
        }.store(in: &subscriptions)
        state.$timerMode.dropFirst().removeDuplicates().sink { [weak self] mode in
            guard let self else { return }
            self.state.clock.pause(now: ProcessInfo.processInfo.systemUptime)
            self.flushFocus(); self.refresh()
            UserDefaults.standard.set(mode.rawValue, forKey: "timerMode")
            self.persist()
        }.store(in: &subscriptions)
        state.$minutes.dropFirst().removeDuplicates().sink { [weak self] minutes in
            guard let self, !self.state.clock.isRunning else { return }
            let clamped = min(720, max(1, minutes))
            self.focusPending = 0
            self.state.countdown = FocusTimer(seconds: Double(clamped * 60))
            UserDefaults.standard.set(clamped, forKey: "timerMinutes")
            self.persist()
        }.store(in: &subscriptions)
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(suspend), name: NSWorkspace.willSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(suspend), name: NSWorkspace.screensDidSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(suspend), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(suspend), name: NSNotification.Name("com.apple.screenIsLocked"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(relocate), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        timer = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in self?.step() }
        RunLoop.main.add(timer!, forMode: .common)
        let mainMenu = NSMenu()
        let appMenu = NSMenu()
        let rootItem = NSMenuItem(); rootItem.submenu = appMenu; mainMenu.addItem(rootItem)
        let plannerItem = NSMenuItem(title: state.tr("하루 플래너"), action: #selector(showPlanner), keyEquivalent: "1")
        plannerItem.target = self; appMenu.addItem(plannerItem)
        appMenu.addItem(NSMenuItem(title: state.tr("종료"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        NSApp.mainMenu = mainMenu
        NSApp.applicationIconImage = PetArtwork.image("rabbit")
        refresh()
        showPlanner()
    }
    @objc func relocate() {
        guard let screen = NSScreen.main else { return }
        panel.setFrameOrigin(NSPoint(x: screen.visibleFrame.maxX - panel.frame.width - 30, y: screen.visibleFrame.minY + 8))
    }
    func resize(_ scale: Double) {
        guard panel != nil else { return }
        var frame = panel.frame
        let centerX = frame.midX
        frame.size = NSSize(width: 250 * scale, height: 380 * scale)
        frame.origin.x = centerX - frame.width / 2
        if let bounds = (panel.screen ?? NSScreen.main)?.visibleFrame {
            frame.origin.x = min(max(frame.origin.x, bounds.minX), max(bounds.minX, bounds.maxX - frame.width))
            frame.origin.y = min(max(frame.origin.y, bounds.minY), max(bounds.minY, bounds.maxY - frame.height))
        }
        panel.setFrame(frame, display: true)
        motion.stop(); targetX = nil
    }
    @objc func showControls() {
        if settings.isVisible { settings.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        let bounds = (panel.screen ?? NSScreen.main)?.visibleFrame ?? panel.frame
        var frame = settings.frame
        if !didPlaceSettings {
            frame.origin.x = panel.frame.minX - frame.width - 12
            frame.origin.y = panel.frame.maxY - frame.height
            didPlaceSettings = true
        }
        frame.origin.x = min(max(frame.origin.x, bounds.minX), max(bounds.minX, bounds.maxX - frame.width))
        frame.origin.y = min(max(frame.origin.y, bounds.minY), max(bounds.minY, bounds.maxY - frame.height))
        settings.setFrame(frame, display: true)
        settings.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    func saveSettings() {
        settings.makeFirstResponder(nil)
        let defaults = UserDefaults.standard
        defaults.set(state.goal, forKey: "workGoal")
        defaults.set(state.showGoal, forKey: "showGoalInBubble")
        defaults.set(state.scale, forKey: "petScale")
        defaults.set(state.wandering, forKey: "wandering")
        defaults.set(state.language.rawValue, forKey: "language")
        defaults.set(state.timerMode.rawValue, forKey: "timerMode")
        defaults.set(min(720, max(1, state.minutes)), forKey: "timerMinutes")
        state.saveAppearance(); state.saveMilestone()
        persist(); savePlan(announce: false)
        settings.saveFrame(usingName: "MoonRabbitSettings")
        state.saved = true
        state.say(state.tr("설정을 저장했어요 ✓"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.state.saved = false }
    }
    func savePlanner() {
        plannerPanel?.makeFirstResponder(nil)
        UserDefaults.standard.set(state.goal, forKey: "workGoal")
        UserDefaults.standard.set(state.showGoal, forKey: "showGoalInBubble")
        state.saveAppearance(); state.saveMilestone(); savePlan()
        state.saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.state.saved = false }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPlanner(); return true
    }
    func savePlan(announce: Bool = true) {
        plannerPanel?.makeFirstResponder(nil)
        if let data = try? JSONEncoder().encode(state.plan) { UserDefaults.standard.set(data, forKey: "dailyPlan") }
        if announce { state.say(state.tr("일정을 저장했어요 ✓"), duration: 8) }
    }
    private var quickToolPanel: NSPanel?
    @objc func showPetMenu() {
        let menu = NSMenu()
        let options: [(String, String)] = [("플래너", "planner"), ("알람", "alarms"), ("메뉴 룰렛", "roulette"), ("🥕 간식", "snack"), ("♡ 웃기", "smile"), ("♫ 춤", "dance"), ("↟ 스트레칭", "stretch"), ("❀ 꽃 주기", "flower"), ("☕ 커피", "coffee"), ("함께 작업하기", "work"), ("오늘 날씨", "weather"), ("날씨 지역 설정", "weatherSettings"), ("설정", "settings")]
        for (label, key) in options {
            if key == "settings" { menu.addItem(.separator()) }
            let item = NSMenuItem(title: state.tr(label), action: #selector(menuAction(_:)), keyEquivalent: "")
            item.target = self; item.representedObject = key; menu.addItem(item)
        }
        motion.stop(); targetX = nil; state.animation.gait = 0
        actionMenuOpen = true
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        actionMenuOpen = false
    }
    @MainActor @objc func menuAction(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        if let activity = PetActivity(rawValue: key) { perform(activity) }
        else if key == "planner" { showPlanner() }
        else if key == "alarms" || key == "roulette" {
            quickToolPanel?.close()
            let content: NSView = key == "alarms" ? NSHostingView(rootView: AlarmSettingsView(state: state)) : NSHostingView(rootView: MealRouletteView(state: state))
            quickToolPanel = companionPanel(title: state.tr(key == "alarms" ? "알람" : "메뉴 룰렛"), content: content, autosave: "RabbitQuick-" + key)
            quickToolPanel?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        else if key == "weather" { reportSavedWeather() }
        else if key == "weatherSettings" { showWeather() }
        else { showControls() }
    }
    func companionPanel(title: String, content: NSView, autosave: String) -> NSPanel {
        let window = NSPanel(contentRect: NSRect(origin: .zero, size: content.fittingSize), styleMask: [.titled, .closable, .utilityWindow], backing: .buffered, defer: false)
        window.title = title; window.contentView = content; window.setContentSize(content.fittingSize)
        window.isReleasedWhenClosed = false; window.level = .floating; window.hidesOnDeactivate = false
        window.isMovableByWindowBackground = true; window.setFrameAutosaveName(autosave)
        if UserDefaults.standard.string(forKey: "NSWindow Frame " + autosave) == nil { window.center() }
        return window
    }
    @objc func showPlanner() {
        if plannerPanel == nil {
            let host = NSHostingView(rootView: DailyPlanView(state: state, save: { [weak self] in self?.savePlanner() }, settings: { [weak self] in self?.showControls() }, toggle: { [weak self] in self?.toggle() }, focus: { [weak self] minutes in self?.startFocus(minutes: minutes) }))
            host.sizingOptions = []
            plannerPanel = companionPanel(title: state.tr("하루 플래너"), content: host, autosave: "MoonRabbitPlannerV2")
            plannerPanel?.styleMask.insert(.resizable)
            plannerPanel?.contentMinSize = NSSize(width: 600, height: 440)
            plannerPanel?.contentMaxSize = NSSize(width: 10000, height: 10000)
            if plannerPanel?.setFrameUsingName("MoonRabbitPlannerV2") != true, let bounds = NSScreen.main?.visibleFrame {
                plannerPanel?.setContentSize(NSSize(width: min(980, bounds.width - 40), height: min(780, bounds.height - 80)))
                plannerPanel?.center()
            }
        }
        plannerPanel?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        let summary = state.plan.modeSummary(day: DailyPlan.key(for: Date()), role: state.activeRole)
        state.say(summary.isEmpty ? state.tr("오늘 일정을 적어볼까요? 🗓") : "🗓 \(summary)", duration: 15)
        importantMessageUntil = Date().addingTimeInterval(15)
    }
    func weatherReport(_ place: WeatherPlace, _ current: CurrentWeather) {
        resumeDialogueAfterWeather = true
        state.say("\(place.name) · \(String(format: "%.1f", current.temperature_2m))°C\n\(state.tr(current.descriptionKey)) · \(state.tr("체감")) \(String(format: "%.1f", current.apparent_temperature))°C", duration: 15)
        state.weatherAttribution = true
        importantMessageUntil = Date().addingTimeInterval(15)
    }
    @MainActor func reportSavedWeather() {
        guard let place = weather.selected else { showWeather(); return }
        state.say(state.tr("날씨 확인 중…"), duration: 20)
        importantMessageUntil = Date().addingTimeInterval(20)
        weather.fetch(place, failed: { [weak self] message in
            guard let self else { return }
            self.state.say(self.state.tr(message), duration: 8)
            self.importantMessageUntil = Date().addingTimeInterval(8)
        }) { [weak self] place, current in self?.weatherReport(place, current) }
    }
    @MainActor func showWeather() {
        if weatherPanel == nil {
            weatherPanel = companionPanel(title: state.tr("날씨"), content: NSHostingView(rootView: WeatherView(state: state, weather: weather, report: { [weak self] place, current in self?.weatherReport(place, current) })), autosave: "MoonRabbitWeather")
        }
        weatherPanel?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        if let place = weather.selected { weather.fetch(place) { [weak self] place, current in self?.weatherReport(place, current) } }
    }
    func flushDailyWork() {
        guard !dailyWorkPending.isEmpty else { return }
        for (day, seconds) in dailyWorkPending { state.plan.workSeconds[day, default: 0] += seconds }
        dailyWorkPending.removeAll()
    }
    func refresh() {
        flushDailyWork()
        state.time = state.clock.display; state.running = state.clock.isRunning
        item.button?.title = "☾ \(state.timerMode == .countdown ? state.countdown.display : String(state.time.dropLast(3)))\(state.running ? " •" : "")"
    }
    func persist() {
        flushDailyWork()
        UserDefaults.standard.set(state.clock.elapsed, forKey: "workSeconds")
        UserDefaults.standard.set(state.countdown.remaining - focusPending, forKey: "remainingSeconds")
        if let data = try? JSONEncoder().encode(state.plan) { UserDefaults.standard.set(data, forKey: "dailyPlan") }
    }
    func startFocus(minutes: Int) {
        if state.clock.isRunning { toggle() }
        state.timerMode = .countdown
        state.minutes = minutes
        focusPending = 0
        state.countdown = FocusTimer(seconds: Double(minutes * 60))
        toggle()
    }
    func toggle() {
        let now = ProcessInfo.processInfo.systemUptime
        if state.clock.isRunning { state.clock.pause(now: now); flushFocus(); state.say(state.tr("잘했어요. 잠깐 차 한 잔 어때요? 🍵")) }
        else {
            if state.minutes < 1 || state.minutes > 720 { state.minutes = min(720, max(1, state.minutes)) }
            if state.timerMode == .countdown && state.countdown.remaining <= 0 {
                focusPending = 0
                state.countdown = FocusTimer(seconds: Double(min(720, max(1, state.minutes)) * 60))
            }
            state.clock.start(now: now)
            let goal = String(state.goal.trimmingCharacters(in: .whitespacesAndNewlines).prefix(32))
            state.say(goal.isEmpty ? state.tr("좋아요! 내가 옆에 있을게요 🌸") : (state.language == .ko ? "오늘의 목표: \(goal)\n함께 해봐요 🌸" : "Today’s goal: \(goal)\nLet’s do this 🌸"))
        }
        refresh(); persist()
    }
    func flushFocus() { _ = state.countdown.advance(by: focusPending); focusPending = 0 }
    @objc func suspend() {
        state.clock.pause(now: ProcessInfo.processInfo.systemUptime)
        flushFocus(); refresh(); persist(); state.say(state.tr("잠시 쉬었어요. 메뉴에서 다시 시작해요."))
    }
    func reset() {
        let alert = NSAlert(); alert.messageText = state.tr(state.timerMode == .countdown ? "타이머를 다시 맞출까요?" : "작업 시간을 0으로 돌릴까요?")
        alert.informativeText = state.tr(state.timerMode == .countdown ? "누적 작업 시간과 목표는 유지합니다." : "지금까지 누적한 시간이 초기화됩니다. 목표는 유지합니다.")
        alert.addButton(withTitle: state.tr("초기화")); alert.addButton(withTitle: state.tr("취소"))
        if alert.runModal() == .alertFirstButtonReturn {
            if state.timerMode == .countdown {
                state.clock.pause(now: ProcessInfo.processInfo.systemUptime)
                focusPending = 0
                state.countdown = FocusTimer(seconds: Double(min(720, max(1, state.minutes)) * 60))
            } else { state.clock.reset() }
            refresh(); persist(); state.say(state.tr("새로운 시작! 준비됐어요 🌱"))
        }
    }
    func setActivity(_ activity: PetActivity) {
        guard state.activity != activity else { return }
        state.activityStart = state.animation.phase
        // Swap front/profile artwork without interpolating a horizontal flip through zero.
        var transaction = Transaction(); transaction.disablesAnimations = true
        withTransaction(transaction) { state.activity = activity }
    }
    func perform(_ activity: PetActivity) {
        playUntil = Date().addingTimeInterval(activity.duration)
        nextPlay = Date().addingTimeInterval(Double.random(in: 25...50))
        motion.stop(); targetX = nil; state.animation.gait = 0
        setActivity(activity)
        state.say(dialogue.next(for: activity, language: state.language), duration: activity.duration)
    }
    func hover(_ inside: Bool) {
        state.hovering = inside
        guard inside, !settings.isVisible, !actionMenuOpen, Date() > importantMessageUntil,
              Date().timeIntervalSince(lastHover) > 6, NSEvent.pressedMouseButtons == 0 else { return }
        lastHover = Date()
        perform([PetActivity.smile, .smile, .flower].randomElement()!)
    }
    func toggleVisibility() {
        state.visible.toggle()
        if state.visible { panel.orderFrontRegardless() } else { panel.orderOut(nil) }
    }
    var scheduleReminderKeys = UserDefaults.standard.stringArray(forKey: "scheduleReminderKeys") ?? []
    var nextScheduleSummary = Date().addingTimeInterval(90)
    func checkScheduleReminders() {
        let now = Date(), calendar = Calendar.current
        var upcoming: [(PlanItem, Date, String)] = []
        for offset in 0...1 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            let key = DailyPlan.key(for: day)
            for item in state.plan.modeItems(day: key, role: state.activeRole) where !item.done && !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                guard let minute = item.startMinute, let start = calendar.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: day), start > now else { continue }
                upcoming.append((item, start, key))
            }
        }
        upcoming.sort { $0.0.priorityRank == $1.0.priorityRank ? $0.1 < $1.1 : $0.0.priorityRank < $1.0.priorityRank }
        var messages: [String] = []
        for (item, start, day) in upcoming {
            for lead in [60, 30, 10] {
                let due = start.addingTimeInterval(Double(-lead * 60))
                let key = "\(day):\(state.roleValue):\(item.id):\(item.time):\(lead)"
                if now >= due && now.timeIntervalSince(due) < 60 && !scheduleReminderKeys.contains(key) {
                    scheduleReminderKeys.append(key)
                    let label = state.tr(item.priorityLabel)
                    messages.append(state.language == .ko ? "[우선순위 \(label)] \(item.title) · \(lead)분 후 시작" : "[\(label) priority] \(item.title) · starts in \(lead) min")
                }
            }
        }
        if !messages.isEmpty {
            scheduleReminderKeys = Array(scheduleReminderKeys.suffix(512))
            UserDefaults.standard.set(scheduleReminderKeys, forKey: "scheduleReminderKeys")
            if !state.visible { toggleVisibility() }
            state.say("⏰ " + messages.joined(separator: "\n"), duration: 25)
            importantMessageUntil = now.addingTimeInterval(25)
            nextScheduleSummary = now.addingTimeInterval(180)
            NSSound(named: NSSound.Name("Glass"))?.play()
        } else if now > nextScheduleSummary, state.message.isEmpty, now > importantMessageUntil {
            nextScheduleSummary = now.addingTimeInterval(180)
            if let (item, _, _) = upcoming.first(where: { $0.1.timeIntervalSince(now) <= 3600 }) {
                state.say(state.language == .ko ? "[우선순위 \(state.tr(item.priorityLabel))] \(item.time) · \(item.title)\n차근차근 준비해 봐요." : "[\(state.tr(item.priorityLabel)) priority] \(item.time) · \(item.title)\nLet’s get ready.", duration: 15)
            }
        }
    }
    func step() {
        let now = ProcessInfo.processInfo.systemUptime
        let dt = min(max(now - lastFrame, 0), 0.1); lastFrame = now
        let before = state.clock.elapsed
        if let hour = state.clock.tick(now: now) { state.say(state.language == .ko ? "벌써 \(hour)시간째 함께 일했어요!\n어깨도 한번 쭉 펴볼까요? 🍵" : "We’ve worked together for \(hour) hour(s)!\nTime for a little stretch? 🍵", duration: 18) }
        let counted = state.clock.elapsed - before
        if counted > 0 { dailyWorkPending[DailyPlan.key(for: Date()), default: 0] += counted }
        if state.timerMode == .countdown { focusPending += counted }
        var focusCompleted = false
        if focusPending >= 1 || (focusPending > 0 && focusPending >= state.countdown.remaining) {
            focusCompleted = state.countdown.advance(by: focusPending); focusPending = 0
        }
        if focusCompleted {
            state.clock.pause(now: now)
            refresh(); persist()
            if !state.visible { toggleVisibility() }
            perform(.smile)
            let goal = String(state.goal.trimmingCharacters(in: .whitespacesAndNewlines).prefix(28))
            state.say(goal.isEmpty ? state.tr("띵! 정한 시간이 다 됐어요 🎉\n수고했어요. 잠깐 쉬어가요!") : (state.language == .ko ? "띵! 집중 시간 완료 🎉\n‘\(goal)’ 수고했어요!" : "Ding! Focus time complete 🎉\nNice work on ‘\(goal)’!"), duration: 30)
            importantMessageUntil = Date().addingTimeInterval(30)
            NSSound(named: NSSound.Name("Glass"))?.play()
        }
        frameCount += 1
        if frameCount % 30 == 0 {
            refresh()
            checkScheduleReminders()
            var alarms = state.alarms
            var due: [String] = []
            for index in alarms.indices {
                if alarms[index].consumeIfDue(now: Date()) { due.append(alarms[index].title.isEmpty ? state.tr("알람 시간이에요!") : alarms[index].title) }
            }
            if !due.isEmpty {
                state.alarms = alarms
                if !state.visible { toggleVisibility() }
                state.say("⏰ " + due.joined(separator: " · "), duration: 25)
                importantMessageUntil = Date().addingTimeInterval(25)
                NSSound(named: NSSound.Name("Glass"))?.play()
            }
        }
        if frameCount % 300 == 0 { persist() }
        if Date() > state.messageUntil, !state.message.isEmpty {
            if resumeDialogueAfterWeather {
                resumeDialogueAfterWeather = false
                state.say(dialogue.next(for: .idle, language: state.language))
            } else { state.message = "" }
        }
        guard state.visible else { return }
        state.animation.phase += dt
        let nowDate = Date()
        if nowDate >= nextBlink {
            blinkUntil = nowDate.addingTimeInterval(0.18)
            nextBlink = nowDate.addingTimeInterval(Double.random(in: 3...7))
        }
        state.animation.blinking = nowDate < blinkUntil
        if nowDate > nextPlay && nowDate > playUntil && state.message.isEmpty {
            perform([PetActivity.snack, .smile, .dance, .stretch, .flower, .coffee, .idle].randomElement()!)
        }
        if nowDate < playUntil { return }
        guard state.wandering, !actionMenuOpen, !state.hovering, NSEvent.pressedMouseButtons == 0 else {
            motion.stop(); state.animation.gait = 0; targetX = nil
            setActivity(.work)
            return
        }
        guard let screen = panel.screen ?? NSScreen.main else { return }
        let bounds = screen.visibleFrame
        let maxX = max(bounds.minX, bounds.maxX - panel.frame.width)
        if targetX == nil && nowDate >= nextWalk {
            targetX = WanderDestination.choose(current: panel.frame.minX, lower: bounds.minX, upper: maxX, fraction: Double.random(in: 0...1))
        }
        guard let target = targetX else { state.animation.gait = 0; setActivity(.work); return }
        var origin = panel.frame.origin
        let previousX = origin.x
        origin.x = motion.advance(x: origin.x, target: target, lower: bounds.minX, upper: maxX,
                                  dt: dt, enabled: true, scale: state.scale)
        origin.y = min(max(origin.y, bounds.minY), max(bounds.minY, bounds.maxY - panel.frame.height))
        panel.setFrameOrigin(origin)
        state.animation.walkDistance += abs(origin.x - previousX) / state.scale
        state.animation.gait = min(1, abs(motion.velocity) / (25 * state.scale))
        if abs(motion.velocity) > 1 {
            var transaction = Transaction(); transaction.disablesAnimations = true
            withTransaction(transaction) { state.animation.facing = motion.velocity < 0 ? -1 : 1 }
        }
        setActivity(state.animation.gait > 0.05 ? .walk : .work)
        if abs(origin.x - min(max(target, bounds.minX), maxX)) < 1 {
            targetX = nil; motion.stop(); state.animation.gait = 0; setActivity(.idle)
            nextWalk = nowDate.addingTimeInterval(Double.random(in: 3...8))
        }
    }

    func applicationWillTerminate(_ notification: Notification) { state.clock.pause(now: ProcessInfo.processInfo.systemUptime); persist(); savePlan(announce: false) }
}
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
