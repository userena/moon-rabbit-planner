import SwiftUI

// Utility panels have a fixed cream surface, so their native controls must use
// the matching appearance even when macOS or the custom planner uses dark colors.
enum SettingsTheme {
    static let background = PetColor(0.97, 0.94, 0.90)
    static let text = PetColor(0.17, 0.14, 0.13)
    static let secondaryText = PetColor(0.38, 0.33, 0.30)
    static let action = PetColor(0.52, 0.35, 0.40)
    static var secondary: Color { secondaryText.color }
}

extension View {
    func settingsSurface() -> some View {
        self.background(SettingsTheme.background.color)
            .foregroundStyle(SettingsTheme.text.color)
            .tint(SettingsTheme.action.color)
            .environment(\.colorScheme, .light)
    }
}

struct SettingsActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 13).padding(.vertical, 6)
            .foregroundStyle(SettingsTheme.action.ink)
            .background(SettingsTheme.action.color, in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).fill(.black.opacity(configuration.isPressed ? 0.12 : 0)))
    }
}
