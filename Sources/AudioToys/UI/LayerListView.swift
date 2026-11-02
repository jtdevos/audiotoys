import SwiftUI

public struct LayerListView: View {
    @ObservedObject var appState: AppState

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("AUDIO LAYERS & DSP CHAINS (\(appState.engine.activeLayers.count))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(AudioToyStyle.textMuted)
                Spacer()

                // Cross-theme layer catalog menu
                Menu {
                    ForEach(ThemeLibrary.defaultThemes) { theme in
                        Menu(theme.title) {
                            ForEach(theme.layers) { layerDef in
                                Button(action: {
                                    appState.addLayerFromCatalog(layerDef)
                                }) {
                                    Text(layerDef.name)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("ADD LAYER")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(AudioToyStyle.accentEmerald)
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .frame(width: 86)
            }
            .padding(.horizontal, 10)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(Array(appState.engine.activeLayers.enumerated()), id: \.element.id) { index, layer in
                        LayerRowView(layer: layer, appState: appState, index: index)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
}

private struct LayerRowView: View {
    @ObservedObject var layer: AudioLayer
    @ObservedObject var appState: AppState
    let index: Int

    var body: some View {
        let isSelected = appState.selectedLayerId == layer.id
        let color = Color(hex: layer.colorHex)
        let profileText = layer.filterChain.profile.rawValue.uppercased()
        let distText = String(format: "d:%.0fcm", layer.currentPosition.magnitude * 100.0)
        let coordText = String(format: "x:%+.2f y:%+.2f z:%+.2f",
                               layer.currentPosition.x, layer.currentPosition.y, layer.currentPosition.z)
        let distColor: Color = layer.proximityPercent > 35 ? AudioToyStyle.accentEmerald : AudioToyStyle.textSecondary
        let rowBg: Color = isSelected ? Color.white.opacity(0.11) : AudioToyStyle.surfaceDark
        let strokeColor: Color = isSelected ? color.opacity(0.75) : Color.white.opacity(0.06)

        HStack(spacing: 8) {
            // Numbered badge matching radar node circle
            Circle()
                .fill(layer.isMuted ? Color.gray.opacity(0.4) : color)
                .frame(width: 16, height: 16)
                .shadow(color: color.opacity(Double(layer.activityLevel)), radius: 4)
                .overlay(
                    Text("\(index + 1)")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(.black)
                )

            // Layer details
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(layer.name)
                        .font(.system(size: 11, weight: isSelected ? .bold : .semibold))
                        .foregroundColor(AudioToyStyle.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    // Acoustic Filter Chain badge
                    Text(profileText)
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundColor(color)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(color.opacity(0.15))
                        .cornerRadius(3)
                }

                // Distance, Proximity Boost & Coordinate readout
                HStack(spacing: 6) {
                    Text(distText)
                        .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(distColor)

                    Text(coordText)
                        .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                        .foregroundColor(AudioToyStyle.textSecondary)
                }
            }

            // Pin/Pause, Mute, Solo buttons
            controlButtons

            // Volume Slider
            Slider(value: Binding(
                get: { Double(layer.volume) },
                set: { layer.volume = Float($0) }
            ), in: 0.0...1.0)
            .frame(width: 56)
            .accentColor(color)
        }
        .padding(8)
        .background(rowBg)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(strokeColor, lineWidth: isSelected ? 1.5 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            appState.selectLayer(withId: layer.id)
        }
    }

    private var controlButtons: some View {
        let isPinned = layer.motionScript.type == .fixed || layer.isMotionPaused
        let pinFg: Color = isPinned ? .orange : AudioToyStyle.textMuted
        let pinBg: Color = isPinned ? Color.orange.opacity(0.2) : Color.white.opacity(0.06)
        let muteFg: Color = layer.isMuted ? .red : AudioToyStyle.textMuted
        let muteBg: Color = layer.isMuted ? Color.red.opacity(0.2) : Color.white.opacity(0.06)
        let soloFg: Color = layer.isSolo ? .yellow : AudioToyStyle.textMuted
        let soloBg: Color = layer.isSolo ? Color.yellow.opacity(0.2) : Color.white.opacity(0.06)

        return HStack(spacing: 3) {
            // Manual Trigger / Audition button for periodic foley & procedural voices
            if layer.isPeriodicOrTriggerable {
                Button(action: {
                    appState.selectLayer(withId: layer.id)
                    layer.triggerAudioFile()
                    appState.scriptStatus = "Triggered \(layer.name)"
                }) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(AudioToyStyle.accentCyan)
                        .frame(width: 18, height: 18)
                        .background(AudioToyStyle.accentCyan.opacity(0.16))
                        .cornerRadius(3)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Trigger / Audition sound immediately")
            }

            // Pin / Resume motion button
            Button(action: {
                appState.selectLayer(withId: layer.id)
                if isPinned {
                    layer.resumeSavedMotion()
                    appState.scriptEditorText = layer.motionScript.rawScript
                    appState.scriptStatus = "Resumed: \(layer.motionScript.type.rawValue)"
                } else {
                    layer.isMotionPaused = true
                    appState.scriptStatus = "Paused at (\(String(format: "%.2f, %.2f", layer.currentPosition.x, layer.currentPosition.z)))"
                }
                appState.objectWillChange.send()
            }) {
                Image(systemName: isPinned ? "pin.fill" : "arrow.triangle.2.circlepath")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(pinFg)
                    .frame(width: 18, height: 18)
                    .background(pinBg)
                    .cornerRadius(3)
            }
            .buttonStyle(PlainButtonStyle())
            .help(isPinned ? "Resume motion orbit/trajectory" : "Freeze / Pin source in place")

            Button(action: {
                layer.isMuted.toggle()
            }) {
                Text("M")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(muteFg)
                    .frame(width: 18, height: 18)
                    .background(muteBg)
                    .cornerRadius(3)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Mute layer")

            Button(action: {
                toggleSolo()
            }) {
                Text("S")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(soloFg)
                    .frame(width: 18, height: 18)
                    .background(soloBg)
                    .cornerRadius(3)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Solo layer")

            if appState.engine.activeLayers.count > 1 {
                Button(action: {
                    appState.removeLayer(withId: layer.id)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(AudioToyStyle.textMuted)
                        .frame(width: 16, height: 18)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(3)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Remove layer from current mix")
            }
        }
    }

    private func toggleSolo() {
        layer.isSolo.toggle()
        let hasAnySolo = appState.engine.activeLayers.contains(where: { $0.isSolo })

        for l in appState.engine.activeLayers {
            if hasAnySolo {
                l.isMuted = !l.isSolo
            } else {
                l.isMuted = false
            }
        }
    }
}
