import SwiftUI

/// A fixed-height list so every choice is reachable with the mouse wheel or trackpad.
struct ScrollTimePicker: View {
    let title: String
    let display: String
    let options: [Int]
    let selected: Int?
    let label: (Int) -> String
    let select: (Int) -> Void
    @State private var expanded = false

    var body: some View {
        Button { expanded.toggle() } label: {
            HStack(spacing: 3) {
                Text(display).monospacedDigit().lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down").font(.system(size: 8))
            }.contentShape(Rectangle())
        }.buttonStyle(.bordered).accessibilityLabel(title)
            .popover(isPresented: $expanded) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title).font(.caption).foregroundStyle(.secondary)
                    ScrollViewReader { reader in
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                ForEach(options, id: \.self) { value in
                                    Button {
                                        select(value)
                                        expanded = false
                                    } label: {
                                        HStack {
                                            Text(label(value)).monospacedDigit()
                                            Spacer()
                                            if selected == value { Image(systemName: "checkmark") }
                                        }.padding(.horizontal, 10).padding(.vertical, 7)
                                            .frame(maxWidth: .infinity)
                                            .background(selected == value ? Color.accentColor.opacity(0.15) : .clear, in: RoundedRectangle(cornerRadius: 6))
                                            .contentShape(Rectangle())
                                    }.buttonStyle(.plain).id(value)
                                }
                            }
                        }.frame(width: 145, height: 230)
                            .onAppear {
                                if let selected, let nearest = PlanningTimeOptions.nearest(to: selected, in: options) {
                                    reader.scrollTo(nearest, anchor: .center)
                                }
                            }
                    }
                }.padding(12)
            }
    }
}

enum PlanningTimeOptions {
    static func nearest(to selected: Int, in options: [Int]) -> Int? {
        guard let lower = options.min(), let upper = options.max() else { return nil }
        if selected <= lower { return lower }
        if selected >= upper { return upper }
        return options.min { abs(Double($0) - Double(selected)) < abs(Double($1) - Double(selected)) }
    }
    static func step(_ value: Int) -> Int { value == 30 ? 30 : 10 }
    static func starts(step: Int) -> [Int] { Array(stride(from: 0, to: 1440, by: self.step(step))) }
    static func durations(step: Int) -> [Int] { Array(stride(from: self.step(step), through: 1440, by: self.step(step))) }
    static func clock(_ minute: Int) -> String { String(format: "%02d:%02d", minute / 60, minute % 60) }
}
