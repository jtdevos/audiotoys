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

            // Description of active theme + Save / Reset actions
            if let active = appState.themes.first(where: { $0.id == appState.selectedThemeId }) {
                HStack(spacing: 8) {
                    Text(active.moodDescription)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(AudioToyStyle.textMuted)
                        .lineLimit(2)

                    Spacer()

                    Button(action: {
                        appState.saveCurrentTheme()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 8.5, weight: .bold))
                            Text("SAVE MIX")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(AudioToyStyle.accentCyan)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(AudioToyStyle.accentCyan.opacity(0.12))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(AudioToyStyle.accentCyan.opacity(0.35), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Save current layer positions, volumes, and motion settings to this theme")

                    Button(action: {
                        appState.resetCurrentTheme()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 8.5, weight: .bold))
                            Text("RESET")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(AudioToyStyle.textSecondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Reset theme to factory default layers and positions")
                }
                .padding(.horizontal, 10)
            }
        }
    }
}
