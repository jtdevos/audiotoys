import SwiftUI
import AppKit

public struct AudioToysMainView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        ZStack {
            AudioToyStyle.bgDark.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Top Header Bar
                headerBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AudioToyStyle.surfaceDark)

                Divider().background(AudioToyStyle.borderGlass)

                // Theme selector strip
                ThemePickerView(appState: appState)
                    .padding(.vertical, 8)
                    .background(AudioToyStyle.surfaceGlass)

                Divider().background(AudioToyStyle.borderGlass)

                // Main Workspace: Radar View on Left, Controls on Right
                HStack(spacing: 0) {
                    // 3D Spatial Radar
                    RadarView(appState: appState)
                        .frame(minWidth: 460, minHeight: 460)
                        .background(Color.black.opacity(0.4))

                    Divider().background(AudioToyStyle.borderGlass)

                    // Right Panel: Layer strip & Script/Filter editor
                    VStack(spacing: 12) {
                        LayerListView(appState: appState)
                            .frame(maxHeight: .infinity)

                        Divider().background(AudioToyStyle.borderGlass)

                        ScriptEditorView(appState: appState)
                    }
                    .frame(width: 375)
                    .padding(10)
                    .background(AudioToyStyle.surfaceDark)
                }

                Divider().background(AudioToyStyle.borderGlass)

                // Bottom Status Footer
                footerBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
            }
        }
        .frame(minWidth: 880, minHeight: 620)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 14) {
            HStack(spacing: 8) {
                Circle()
                    .fill(appState.engine.isRunning ? AudioToyStyle.accentEmerald : Color.gray)
                    .frame(width: 10, height: 10)
                    .shadow(color: appState.engine.isRunning ? AudioToyStyle.accentEmerald : .clear, radius: 4)

                VStack(alignment: .leading, spacing: 1) {
                    Text("AUDIOTOYS • BINAURAL ASMR STUDIO")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(AudioToyStyle.textPrimary)

                    Text("HRTFHQ Near-Field Spatial Audio • 5-Stage Acoustic DSP Filter Chain")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(AudioToyStyle.textMuted)
                }
            }

            Spacer()

            // Near-Field ASMR Proximity Boost Slider
            HStack(spacing: 5) {
                Text("PROXIMITY:")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(AudioToyStyle.accentEmerald)

                Slider(value: Binding(
                    get: { Double(appState.engine.asmrProximityBoost) },
                    set: { appState.engine.asmrProximityBoost = Float($0) }
                ), in: 0.0...1.5)
                .frame(width: 70)
                .accentColor(AudioToyStyle.accentEmerald)

                Text(String(format: "%d%%", Int((appState.engine.asmrProximityBoost * 100.0).rounded())))
                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(AudioToyStyle.textSecondary)
                    .frame(width: 30, alignment: .leading)
            }

            // Reverb Selector
            HStack(spacing: 4) {
                Text("ROOM:")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(AudioToyStyle.textMuted)

                Picker("", selection: Binding(
                    get: { appState.engine.currentReverb },
                    set: { appState.engine.currentReverb = $0 }
                )) {
                    ForEach(ReverbEnvironmentPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 125)
            }

            // Master Volume
            HStack(spacing: 4) {
                Text("🔊")
                    .font(.system(size: 10))
                Slider(value: Binding(
                    get: { Double(appState.engine.masterVolume) },
                    set: { appState.engine.masterVolume = Float($0) }
                ), in: 0.0...1.0)
                .frame(width: 75)
                .accentColor(AudioToyStyle.accentCyan)
            }

            // Play / Pause Button
            Button(action: {
                if appState.engine.isRunning {
                    appState.engine.stop()
                } else {
                    appState.engine.start()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: appState.engine.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(appState.engine.isRunning ? "PAUSE" : "START")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(appState.engine.isRunning ? Color.orange : AudioToyStyle.accentEmerald)
                .cornerRadius(4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Footer Bar

    private var footerBar: some View {
        HStack {
            Text("DSP Chain: HPF → 165Hz Proximity Shelf → Formant EQ → 7.5kHz Air / Pinna LPF → Transient Exciter → HRTFHQ")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(AudioToyStyle.textMuted)

            Spacer()

            Text(String(format: "Time: %.1fs • Active Layers: %d", appState.engine.elapsedTime, appState.engine.activeLayers.count))
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(AudioToyStyle.textSecondary)
        }
    }
}

public class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let appState = AppState()

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = AudioToysMainView(appState: appState)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 660),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "AudioToys — Binaural ASMR & Spatial Audio Studio"
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
