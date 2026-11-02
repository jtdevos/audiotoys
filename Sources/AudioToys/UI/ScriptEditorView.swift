import SwiftUI

public struct ScriptEditorView: View {
    @ObservedObject var appState: AppState

    public var body: some View {
        let selectedLayer = appState.engine.activeLayers.first(where: { $0.id == appState.selectedLayerId })

        VStack(alignment: .leading, spacing: 8) {
            if let layer = selectedLayer {
                LayerInspectorContentView(layer: layer, appState: appState)
            } else {
                Text("Select an audio layer on the radar or list to position it or adjust its DSP profile.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(AudioToyStyle.textMuted)
                    .padding(.vertical, 6)
            }
        }
        .padding(8)
        .background(AudioToyStyle.surfaceGlass)
        .cornerRadius(6)
    }
}

private struct LayerInspectorContentView: View {
    @ObservedObject var layer: AudioLayer
    @ObservedObject var appState: AppState
    @State private var showRawScriptEditor: Bool = false

    private var isPinned: Bool {
        layer.motionScript.type == .fixed || layer.isMotionPaused
    }

    var body: some View {
        let color = Color(hex: layer.colorHex)

        VStack(alignment: .leading, spacing: 7) {
            // Header row
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(layer.name.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                    .lineLimit(1)

                Spacer()

                Text(appState.scriptStatus)
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .foregroundColor(appState.isScriptError ? .red : AudioToyStyle.accentEmerald)
                    .lineLimit(1)

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showRawScriptEditor.toggle()
                    }
                }) {
                    Text("</> SCRIPT")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(showRawScriptEditor ? AudioToyStyle.accentCyan : AudioToyStyle.textMuted)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(showRawScriptEditor ? 0.14 : 0.06))
                        .cornerRadius(3)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Acoustic Filter Profile Selector
            HStack(spacing: 6) {
                Text("DSP PROFILE:")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundColor(AudioToyStyle.textSecondary)

                Picker("", selection: Binding(
                    get: { layer.filterChain.profile },
                    set: { newProfile in
                        layer.filterChain.setProfile(newProfile)
                        layer.objectWillChange.send()
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

            // Motion Mode Pills (No coding required)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    Button(action: {
                        appState.pinLayer(layer, at: layer.currentPosition)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 7.5))
                            Text("Pinned")
                        }
                        .font(.system(size: 8.5, weight: isPinned ? .bold : .medium, design: .monospaced))
                        .foregroundColor(isPinned ? .black : AudioToyStyle.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3.5)
                        .background(isPinned ? Color.orange : Color.white.opacity(0.07))
                        .cornerRadius(3)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if isPinned, layer.savedMotionScriptBeforePin != nil {
                        Button(action: {
                            layer.resumeSavedMotion()
                            appState.scriptEditorText = layer.motionScript.rawScript
                            appState.scriptStatus = "Resumed: \(layer.motionScript.type.rawValue)"
                            appState.objectWillChange.send()
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 7))
                                Text("Resume")
                            }
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3.5)
                            .background(AudioToyStyle.accentEmerald)
                            .cornerRadius(3)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    presetButton(
                        "Orbit",
                        isActive: !isPinned && layer.motionScript.type == .orbit,
                        script: String(format: "orbit radius=%.2f speed=0.14 height=%.2f phase=0.0", max(0.22, layer.currentPosition.horizontalDistance), layer.currentPosition.y)
                    )
                    presetButton(
                        "Ear-to-Ear",
                        isActive: !isPinned && layer.motionScript.rawScript.contains("0.28*t"),
                        script: "expr x=0.24*sin(0.28*t); y=0.0; z=0.14*cos(0.56*t)"
                    )
                    presetButton(
                        "Nape Sweep",
                        isActive: !isPinned && layer.motionScript.rawScript.contains("z=0.22"),
                        script: "expr x=0.22*sin(0.35*t); y=-0.06; z=0.22"
                    )
                    presetButton(
                        "Wander",
                        isActive: !isPinned && layer.motionScript.type == .wander,
                        script: String(format: "wander radius=%.2f speed=0.22 jitter=0.15", max(0.25, layer.currentPosition.horizontalDistance))
                    )
                    presetButton(
                        "Lissajous",
                        isActive: !isPinned && layer.motionScript.type == .lissajous,
                        script: "lissajous xR=0.26 yR=0.09 zR=0.24 xF=0.18 yF=0.29 zF=0.14"
                    )
                    presetButton(
                        "Spiral",
                        isActive: !isPinned && layer.motionScript.type == .spiral,
                        script: "spiral min=0.18 max=0.65 speed=0.14 vSpeed=0.10 vAmp=0.15"
                    )
                }
            }

            // Direct Position / Trajectory Sliders
            if isPinned {
                let maxCoord: Double = appState.isNearFieldRadar ? 0.90 : 3.50
                VStack(spacing: 4) {
                    sliderRow(
                        label: "LEFT/RIGHT",
                        valueText: String(format: "%+.2fm", layer.currentPosition.x),
                        value: Binding(
                            get: { Double(layer.currentPosition.x) },
                            set: { newX in
                                let pos = Vector3(Float(newX), layer.currentPosition.y, layer.currentPosition.z)
                                appState.pinLayer(layer, at: pos)
                            }
                        ),
                        range: -maxCoord...maxCoord,
                        tint: color
                    )
                    sliderRow(
                        label: "FRONT/BACK",
                        valueText: String(format: "%+.2fm", layer.currentPosition.z),
                        value: Binding(
                            get: { Double(layer.currentPosition.z) },
                            set: { newZ in
                                let pos = Vector3(layer.currentPosition.x, layer.currentPosition.y, Float(newZ))
                                appState.pinLayer(layer, at: pos)
                            }
                        ),
                        range: -maxCoord...maxCoord,
                        tint: color
                    )
                    sliderRow(
                        label: "HEIGHT (Y)",
                        valueText: String(format: "%+.2fm", layer.currentPosition.y),
                        value: Binding(
                            get: { Double(layer.currentPosition.y) },
                            set: { newY in
                                let pos = Vector3(layer.currentPosition.x, Float(newY), layer.currentPosition.z)
                                appState.pinLayer(layer, at: pos)
                            }
                        ),
                        range: -0.80...0.80,
                        tint: color
                    )
                }
            } else {
                let maxRad: Double = appState.isNearFieldRadar ? 1.00 : 3.50
                VStack(spacing: 4) {
                    sliderRow(
                        label: "RADIUS",
                        valueText: String(format: "%.0fcm", layer.motionScript.effectiveRadius * 100.0),
                        value: Binding(
                            get: { Double(layer.motionScript.effectiveRadius) },
                            set: { newR in
                                layer.motionScript.updateRadius(Float(newR))
                                layer.savedMotionScriptBeforePin = layer.motionScript.rawScript
                                appState.scriptEditorText = layer.motionScript.rawScript
                                layer.objectWillChange.send()
                                appState.objectWillChange.send()
                            }
                        ),
                        range: 0.12...maxRad,
                        tint: color
                    )
                    sliderRow(
                        label: "SPEED",
                        valueText: String(format: "%.2fx", layer.motionScript.effectiveSpeed),
                        value: Binding(
                            get: { Double(layer.motionScript.effectiveSpeed) },
                            set: { newSpd in
                                layer.motionScript.updateSpeed(Float(newSpd))
                                layer.savedMotionScriptBeforePin = layer.motionScript.rawScript
                                appState.scriptEditorText = layer.motionScript.rawScript
                                layer.objectWillChange.send()
                                appState.objectWillChange.send()
                            }
                        ),
                        range: 0.03...0.85,
                        tint: color
                    )
                    sliderRow(
                        label: "HEIGHT (Y)",
                        valueText: String(format: "%+.2fm", layer.motionScript.effectiveElevation),
                        value: Binding(
                            get: { Double(layer.motionScript.effectiveElevation) },
                            set: { newY in
                                layer.motionScript.updateElevation(Float(newY))
                                layer.savedMotionScriptBeforePin = layer.motionScript.rawScript
                                appState.scriptEditorText = layer.motionScript.rawScript
                                layer.objectWillChange.send()
                                appState.objectWillChange.send()
                            }
                        ),
                        range: -0.80...0.80,
                        tint: color
                    )
                }
            }

            // Collapsible Raw Script Editor for Custom Math Expressions
            if showRawScriptEditor {
                HStack(spacing: 6) {
                    TextField("Enter motion script...", text: $appState.scriptEditorText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(5)
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
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(AudioToyStyle.accentCyan)
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func sliderRow(label: String, valueText: String, value: Binding<Double>, range: ClosedRange<Double>, tint: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(AudioToyStyle.textMuted)
                .frame(width: 66, alignment: .leading)

            Slider(value: value, in: range)
                .accentColor(tint)

            Text(valueText)
                .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                .foregroundColor(AudioToyStyle.textSecondary)
                .frame(width: 44, alignment: .trailing)
        }
    }

    private func presetButton(_ title: String, isActive: Bool, script: String) -> some View {
        Button(action: {
            appState.applyScriptToSelectedLayer(script)
        }) {
            Text(title)
                .font(.system(size: 8.5, weight: isActive ? .bold : .medium, design: .monospaced))
                .foregroundColor(isActive ? .black : AudioToyStyle.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3.5)
                .background(isActive ? AudioToyStyle.accentCyan : Color.white.opacity(0.07))
                .cornerRadius(3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
