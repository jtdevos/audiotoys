import SwiftUI

public struct ScriptEditorView: View {
    @ObservedObject var appState: AppState

    public var body: some View {
        let selectedLayer = appState.engine.activeLayers.first(where: { $0.id == appState.selectedLayerId })

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MOTION & FILTER INSPECTOR")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(AudioToyStyle.textMuted)

                if let layer = selectedLayer {
                    Text("• \(layer.name)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: layer.colorHex))
                        .lineLimit(1)
                }

                Spacer()

                Text(appState.scriptStatus)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(appState.isScriptError ? .red : AudioToyStyle.accentEmerald)
            }

            if let layer = selectedLayer {
                // Acoustic Filter Profile Selector for Selected Layer
                HStack(spacing: 6) {
                    Text("DSP PROFILE:")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(AudioToyStyle.textSecondary)

                    Picker("", selection: Binding(
                        get: { layer.filterChain.profile },
                        set: { newProfile in
                            layer.filterChain.setProfile(newProfile)
                            appState.objectWillChange.send()
                        }
                    )) {
                        ForEach(AcousticProfile.allCases, id: \.self) { prof in
                            Text(prof.rawValue).tag(prof)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity)
                }

                // Script editor text area
                HStack(spacing: 6) {
                    TextField("Enter motion script...", text: $appState.scriptEditorText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(AudioToyStyle.surfaceDark)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(appState.isScriptError ? Color.red.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1)
                        )

                    Button(action: {
                        appState.applyScriptToSelectedLayer(appState.scriptEditorText)
                    }) {
                        Text("RUN")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AudioToyStyle.accentCyan)
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Near-Field ASMR & Spatial Preset Pills
                HStack(spacing: 4) {
                    presetButton("Ear-to-Ear", script: "expr x=0.24*sin(0.28*t); y=0.0; z=0.14*cos(0.56*t)")
                    presetButton("Close Orbit", script: "orbit radius=0.25 speed=0.14 height=0.04")
                    presetButton("Nape Sweep", script: "expr x=0.22*sin(0.35*t); y=-0.06; z=0.22")
                    presetButton("Lissajous", script: "lissajous xR=0.26 yR=0.09 zR=0.24 xF=0.18 yF=0.29 zF=0.14")
                    presetButton("Spiral", script: "spiral min=0.18 max=0.65 speed=0.14 vSpeed=0.10 vAmp=0.15")
                    presetButton("Wander", script: "wander radius=0.32 speed=0.22 jitter=0.15")
                }
            } else {
                Text("Select an audio layer on the radar or list to inspect its 5-stage DSP filter chain and 3D trajectory.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(AudioToyStyle.textMuted)
                    .padding(.vertical, 4)
            }
        }
        .padding(8)
        .background(AudioToyStyle.surfaceGlass)
        .cornerRadius(6)
    }

    private func presetButton(_ title: String, script: String) -> some View {
        Button(action: {
            appState.applyScriptToSelectedLayer(script)
        }) {
            Text(title)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(AudioToyStyle.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.06))
                .cornerRadius(3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
