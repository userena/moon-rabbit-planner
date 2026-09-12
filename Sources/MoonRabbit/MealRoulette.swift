import SwiftUI

struct MealRouletteView: View {
    @ObservedObject var state: PetState
    @AppStorage("mealCandidate1") private var first = ""
    @AppStorage("mealCandidate2") private var second = ""
    @AppStorage("mealCandidate3") private var third = ""
    @State private var result = ""
    @State private var spinning = false
    @State private var spinTask: Task<Void, Never>?
    var ko: Bool { state.language == .ko }
    var candidates: [String] { [first, second, third].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.reduce(into: []) { if !$0.contains($1) { $0.append($1) } } }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(ko ? "점심 · 저녁 메뉴 룰렛" : "Lunch · dinner roulette").font(.title2.bold())
            Text(ko ? "서로 다른 메뉴를 2~3개 적어주세요." : "Enter 2–3 different meals.").foregroundStyle(.secondary)
            TextField(ko ? "메뉴 1" : "Meal 1", text: $first)
            TextField(ko ? "메뉴 2" : "Meal 2", text: $second)
            TextField(ko ? "메뉴 3 (선택)" : "Meal 3 (optional)", text: $third)
            Text(result.isEmpty ? "🍽" : result).font(.system(size: 28, weight: .semibold)).frame(maxWidth: .infinity, minHeight: 70)
                .padding(8).background(state.appearance.plannerAccent.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel((ko ? "선택 결과: " : "Result: ") + result)
            Button(spinning ? (ko ? "고르는 중…" : "Spinning…") : (ko ? "돌리기" : "Spin")) {
                let choices = candidates
                guard choices.count >= 2 else { return }
                spinning = true
                spinTask = Task { @MainActor in
                    for index in 0..<16 {
                        guard !Task.isCancelled else { return }
                        result = choices[index % choices.count]
                        try? await Task.sleep(nanoseconds: UInt64(60 + index * 10) * 1_000_000)
                    }
                    guard !Task.isCancelled else { return }
                    result = choices.randomElement()!
                    spinning = false
                    state.say(ko ? "오늘 메뉴는 ‘\(result)’! 맛있게 먹어요 🍽" : "Today’s pick: \(result)! Enjoy 🍽", duration: 15)
                }
            }.buttonStyle(.borderedProminent).disabled(spinning || candidates.count < 2)
        }.textFieldStyle(.roundedBorder).padding(22).frame(width: 330)
            .onDisappear { spinTask?.cancel(); spinning = false }
    }
}
