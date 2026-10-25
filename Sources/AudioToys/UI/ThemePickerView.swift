import SwiftUI

public struct ThemePickerView: View {
    @ObservedObject var appState: AppState

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(appState.themes) { theme in
                        let isSelected = theme.id == appState.selectedThemeId

                        Button(action: {
                            appState.selectTheme(withId: theme.id)
                        }) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(isSelected ? AudioToyStyle.accentCyan : Color.white.opacity(0.3))
                                    .frame(width: 6, height: 6)

                                Text(theme.title)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : AudioToyStyle.textSecondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.white.opacity(0.12) : AudioToyStyle.surfaceDark)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isSelected ? AudioToyStyle.accentCyan.opacity(0.6) : Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 8)
            }

            // Description of active theme
            if let active = appState.themes.first(where: { $0.id == appState.selectedThemeId }) {
                Text(active.moodDescription)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(AudioToyStyle.textMuted)
                    .lineLimit(2)
                    .padding(.horizontal, 10)
            }
        }
    }
}
