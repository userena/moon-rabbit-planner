import Foundation

enum PetActivity: String, CaseIterable {
    case idle, walk, snack, smile, dance, stretch, flower, coffee, work
    var artwork: String {
        switch self {
        case .idle, .walk: return "rabbit"
        case .snack: return "snack"
        case .smile: return "smile"
        case .dance: return "dance"
        case .stretch: return "stretch"
        case .flower: return "flower"
        case .coffee: return "coffee"
        case .work: return "workLaptop0"
        }
    }
    var duration: Double { [.snack, .stretch, .flower, .coffee, .work].contains(self) ? 8 : (self == .dance ? 7 : 5) }
}

/// Smooth arrival with bounded velocity; a parked pet never drifts.
struct WanderMotion {
    private(set) var velocity = 0.0
    mutating func stop() { velocity = 0 }
    mutating func advance(x: Double, target: Double, lower: Double, upper: Double,
                          dt: Double, enabled: Bool, scale: Double = 1) -> Double {
        let upper = max(lower, upper)
        let position = min(max(x, lower), upper)
        guard enabled else { stop(); return position }
        let goal = min(max(target, lower), upper)
        let distance = goal - position
        if abs(distance) < 0.5 { stop(); return goal }
        let delta = min(max(dt, 0), 0.1)
        let desired = min(46 * scale, abs(distance) * 1.8) * (distance < 0 ? -1 : 1)
        velocity += (desired - velocity) * min(1, delta * 4)
        let next = position + velocity * delta
        if (goal - next) * distance < 0 { stop(); return goal }
        return min(max(next, lower), upper)
    }
}

struct PetDialogue {
    private var previous: [PetActivity: String] = [:]
    static let lines: [PetActivity: [String]] = [
        .work: ["같이 차근차근 해봐요 🌿", "다음 한 가지에 집중해요.", "곁에서 함께 작업할게요."],
        .coffee: ["커피 한 모금, 나랑 잠깐 쉬어요 ☕", "후후, 따뜻해요. 오늘도 수고했어요!", "잔을 살짝 들어요. 우리를 위한 건배 ☕", "향긋한 커피처럼 편안한 순간이에요."],
        .idle: ["오늘도 네 편이에요 🌸", "한 번에 한 가지씩, 천천히 해봐요.", "작은 진전도 반짝반짝 빛나요 ✨", "난 여기서 조용히 응원할게요.", "어깨에 힘 빼고, 숨 한번 후—", "물 한 모금 챙겨 마셔요 💧", "지금까지 해낸 것도 꽤 많을 거예요.", "서두르지 않아도 괜찮아요 🌱"],
        .walk: ["사뿐사뿐, 응원 배달 갑니다 🌷", "잠깐 산책하고 올게요!", "좋은 생각을 주워 올게요 ✨", "발소리는 살금살금, 응원은 듬뿍!"],
        .snack: ["아삭아삭! 당근 충전 중 🥕", "한 입 먹고 힘내볼까요?", "냠냠… 너도 간식 챙겨요!", "오늘의 당근, 별 다섯 개! ⭐", "볼이 빵빵해도 응원은 할 수 있어요.", "맛있는 건 천천히 먹어야 해요 🥕"],
        .smile: ["헤헤, 네가 있어서 좋아요 ♡", "지금 웃으면 기분이 조금 좋아질지도!", "토닥토닥, 잘하고 있어요 🌷", "오늘의 작은 행운은 이 미소예요.", "눈이 마주쳤다! 웃음 선물 😊", "활짝! 이만큼 응원하고 있어요.", "완벽하지 않아도 충분히 멋져요.", "조금 쉬어도 응원은 계속돼요 ♡"],
        .stretch: ["기지개 쭈욱! 어깨도 살짝 펴요 🌿", "굽은 어깨를 천천히 활짝~", "손끝을 하늘로, 숨은 편안하게.", "잠깐 몸을 펴니 기분도 가벼워요!"],
        .flower: ["수고한 너에게 꽃 한 송이 🌸", "이 꽃은 오늘의 작은 응원이에요.", "반짝이는 하루가 되길! 받아줄래요?", "말 대신 꽃으로 전하는 토닥토닥 ♡"],
        .dance: ["둠칫둠칫, 응원 춤 나갑니다 ♪", "왼발, 오른발! 기분도 가볍게 ♫", "수고한 너를 위한 작은 공연!", "깡총! 좋은 기운 받아요 ✨", "어깨도 같이 살짝 들썩여볼까요?", "오늘의 주인공에게 박수! 짝짝 👏"]
    ]
    static let english: [PetActivity: [String]] = [
        .work: ["One step at a time, together 🌿", "Let’s focus on the next small thing.", "I’ll work right here beside you."],
        .coffee: ["A little coffee break with me? ☕", "Warm and cozy. You did well today!", "Raise your cup. Cheers to us ☕", "A quiet moment and a lovely coffee aroma."],
        .idle: ["I'm on your side today 🌸", "One little step at a time.", "Small steps sparkle, too ✨", "I'll cheer for you quietly.", "Relax your shoulders. Breathe out…", "A sip of water, perhaps? 💧", "Look at all you've done already!", "It's okay to take your time 🌱"],
        .walk: ["Special delivery: a little encouragement 🌷", "Off for a tiny stroll!", "I'll look for a bright idea ✨", "Quiet footsteps, lots of support!"],
        .snack: ["Crunch, crunch! Carrot recharge 🥕", "A little bite, a little energy!", "Nom nom… grab a snack, too!", "Today's carrot gets five stars ⭐", "Full cheeks, full of encouragement!", "Good snacks deserve a slow bite 🥕"],
        .smile: ["Hehe, glad you're here ♡", "Here's a smile for your day!", "You're doing well. Little pats 🌷", "A tiny smile, a tiny bit of luck.", "Our eyes met! A smile for you 😊", "This is how much I believe in you!", "You don't have to be perfect.", "Even on breaks, I'm cheering for you ♡"],
        .dance: ["A little dance to cheer you on ♪", "Left foot, right foot, lighter mood ♫", "A tiny show just for you!", "Hop! Sending good energy ✨", "Want to give your shoulders a wiggle?", "A round of applause for you 👏"],
        .stretch: ["Stretch up! Open your shoulders 🌿", "Gently roll those shoulders back.", "Reach up and breathe comfortably.", "A little stretch feels so refreshing!"],
        .flower: ["A flower for all your hard work 🌸", "A tiny bloom of encouragement.", "Hope your day sparkles. For you!", "A flower-shaped little hug ♡"]
    ]
    mutating func next(for activity: PetActivity, language: AppLanguage = .ko) -> String {
        let library = language == .ko ? Self.lines : Self.english
        let choices = library[activity, default: library[.idle]!]
        let selected = choices.filter { $0 != previous[activity] }.randomElement() ?? choices[0]
        previous[activity] = selected
        return selected
    }
}

/// Prefer a meaningful trip to avoid appearing parked when a nearby target is chosen.
enum WanderDestination {
    static func choose(current: Double, lower: Double, upper: Double, fraction: Double) -> Double {
        guard upper > lower else { return lower }
        let candidate = lower + (upper - lower) * min(1, max(0, fraction))
        let minimumTrip = min(140, (upper - lower) * 0.3)
        if abs(candidate - current) >= minimumTrip { return candidate }
        return current - lower > upper - current ? lower : upper
    }
}

enum WalkCycle {
    static func frame(distance: Double) -> Int {
        guard distance.isFinite, distance >= 0 else { return 0 }
        return Int(distance.truncatingRemainder(dividingBy: 64) / 16) % 4
    }
}
