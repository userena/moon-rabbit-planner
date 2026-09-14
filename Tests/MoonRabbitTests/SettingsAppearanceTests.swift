import XCTest
import SwiftUI
import AppKit
@testable import MoonRabbit

final class SettingsAppearanceTests: XCTestCase {
    @MainActor
    func testSettingsRenderingAcrossSystemAppearances() throws {
        // Render offscreen without changing real planner records; PNG export is opt-in.
        let directory = ProcessInfo.processInfo.environment["MOONRABBIT_SNAPSHOT_DIR"]
        if let directory { try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true) }
        for language in [AppLanguage.ko, .en] {
        for (modeName, mode) in [("stopwatch", TimerMode.stopwatch), ("countdown", .countdown)] {
        for (name, scheme, appearance) in [("light", ColorScheme.light, NSAppearance.Name.aqua), ("dark", .dark, .darkAqua)] {
            let state = PetState()
            state.language = language
            state.timerMode = mode
            state.goal = "오늘의 목표 · Today's goal"
            let root = ControlView(state: state, toggle: {}, reset: {}, perform: { _ in }, hide: {}, save: {}, planner: {})
                .environment(\.colorScheme, scheme)
            let host = NSHostingView(rootView: root)
            host.appearance = NSAppearance(named: appearance)
            let size = host.fittingSize
            host.frame = NSRect(origin: .zero, size: size)
            host.layoutSubtreeIfNeeded()
            // Let AppKit finish reconciling the inherited and local appearances.
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            host.layoutSubtreeIfNeeded()
            let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: bitmap)
            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
            if let directory { try png.write(to: URL(fileURLWithPath: directory).appendingPathComponent("settings-\(language.rawValue)-\(modeName)-\(name).png")) }
            // The timer must remain dark on the fixed cream panel in both modes.
            // The old dark-mode rendering was white-on-cream and fails this check.
            let scale = Double(bitmap.pixelsWide) / 300
            var readablePixels = 0
            for y in Int(145 * scale)..<Int(185 * scale) {
                for x in Int(15 * scale)..<Int(190 * scale) {
                    if let c = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB),
                       max(c.redComponent, c.greenComponent, c.blueComponent) < 0.4, c.alphaComponent > 0.9 {
                        readablePixels += 1
                    }
                }
            }
            XCTAssertGreaterThan(readablePixels, 50, "Timer text disappeared in \(name) appearance")
            XCTAssertGreaterThan(bitmap.pixelsHigh, 300)
        }
        }
        }
    }
}
