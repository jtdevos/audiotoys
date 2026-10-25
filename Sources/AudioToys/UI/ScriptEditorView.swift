import SwiftUI

public struct ScriptEditorView: View {
    @ObservedObject var appState: AppState

    public var body: some View {
        let selectedLayer = appState.engine.activeLayers.first(where: { $0.id == appState.selectedLayerId })

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MOTION SCRIPT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(AudioToyStyle.textMuted)

                if let layer = selectedLayer {
                    Text("• \(layer.name)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: layer.colorHex))
                }

                Spacer()

                Text(appState.scriptStatus)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(appState.isScriptError ? .red : AudioToyStyle.accentEmerald)
            }

            if let _ = selectedLayer {
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

                // Preset Pills
                HStack(spacing: 4) {
                    presetButton("Orbit", script: "orbit radius=2.5 speed=0.4 height=0.0")
                    presetButton("Lissajous", script: "lissajous xR=2.2 yR=0.7 zR=1.8 xF=0.4 yF=0.7 zF=0.3")
                    presetButton("Spiral", script: "spiral min=0.5 max=3.5 speed=0.3 vSpeed=0.15 vAmp=0.8")
                    presetButton("Pendulum", script: "pendulum length=2.0 angle=45 freq=0.8 axis=x")
                    presetButton("Wander", script: "wander radius=3.0 speed=0.4 jitter=0.2")
                    presetButton("Math Expr", script: "expr x=2.5*cos(0.6*t); y=0.4*sin(1.2*t); z=2.0*sin(0.6*t)")
                }
            } else {
                Text("Select an audio layer on the radar or list to live-script its 3D motion.")
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
