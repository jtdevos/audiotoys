import SwiftUI

public struct LayerListView: View {
    @ObservedObject var appState: AppState

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AUDIO LAYERS (\(appState.engine.activeLayers.count))")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(AudioToyStyle.textMuted)
                .padding(.horizontal, 10)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(appState.engine.activeLayers) { layer in
                        layerRow(layer: layer)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private func layerRow(layer: AudioLayer) -> some View {
        let isSelected = appState.selectedLayerId == layer.id
        let color = Color(hex: layer.colorHex)

        return HStack(spacing: 8) {
            // Color indicator dot
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            // Layer details
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(layer.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AudioToyStyle.textPrimary)

                    Spacer()

                    // Motion badge
                    Text(layer.motionScript.type.rawValue.uppercased())
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(color)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(color.opacity(0.15))
                        .cornerRadius(3)
                }

                // Coordinate readout
                Text(String(format: "x:%+.1fm  y:%+.1fm  z:%+.1fm",
                            layer.currentPosition.x, layer.currentPosition.y, layer.currentPosition.z))
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(AudioToyStyle.textSecondary)
            }

            // Mute / Solo buttons
            HStack(spacing: 4) {
                Button(action: {
                    layer.isMuted.toggle()
                }) {
                    Text("M")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(layer.isMuted ? .red : AudioToyStyle.textMuted)
                        .frame(width: 18, height: 18)
                        .background(layer.isMuted ? Color.red.opacity(0.2) : Color.white.opacity(0.06))
                        .cornerRadius(3)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    toggleSolo(layer: layer)
                }) {
                    Text("S")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(layer.isSolo ? .yellow : AudioToyStyle.textMuted)
                        .frame(width: 18, height: 18)
                        .background(layer.isSolo ? Color.yellow.opacity(0.2) : Color.white.opacity(0.06))
                        .cornerRadius(3)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Volume Slider
            Slider(value: Binding(
                get: { Double(layer.volume) },
                set: { layer.volume = Float($0) }
            ), in: 0.0...1.0)
            .frame(width: 65)
            .accentColor(color)
        }
        .padding(8)
        .background(isSelected ? Color.white.opacity(0.09) : AudioToyStyle.surfaceDark)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? color.opacity(0.6) : Color.white.opacity(0.06), lineWidth: 1)
        )
        .onTapGesture {
            appState.selectLayer(withId: layer.id)
        }
    }

    private func toggleSolo(layer: AudioLayer) {
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
