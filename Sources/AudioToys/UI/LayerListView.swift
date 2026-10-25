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
            }
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
        let profileText = layer.filterChain.profile.rawValue.uppercased()
        let distText = String(format: "d:%.0fcm", layer.currentPosition.magnitude * 100.0)
        let coordText = String(format: "x:%+.2f y:%+.2f z:%+.2f",
                               layer.currentPosition.x, layer.currentPosition.y, layer.currentPosition.z)
        let distColor: Color = layer.proximityPercent > 35 ? AudioToyStyle.accentEmerald : AudioToyStyle.textSecondary
        let rowBg: Color = isSelected ? Color.white.opacity(0.09) : AudioToyStyle.surfaceDark
        let strokeColor: Color = isSelected ? color.opacity(0.6) : Color.white.opacity(0.06)

        return HStack(spacing: 8) {
            // Color & live activity indicator dot
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(Double(layer.activityLevel)), radius: 4)

            // Layer details
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(layer.name)
                        .font(.system(size: 11, weight: .semibold))
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

            // Mute / Solo buttons
            muteSoloButtons(layer: layer)

            // Volume Slider
            Slider(value: Binding(
                get: { Double(layer.volume) },
                set: { layer.volume = Float($0) }
            ), in: 0.0...1.0)
            .frame(width: 60)
            .accentColor(color)
        }
        .padding(8)
        .background(rowBg)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(strokeColor, lineWidth: 1)
        )
        .onTapGesture {
            appState.selectLayer(withId: layer.id)
        }
    }

    private func muteSoloButtons(layer: AudioLayer) -> some View {
        let muteFg: Color = layer.isMuted ? .red : AudioToyStyle.textMuted
        let muteBg: Color = layer.isMuted ? Color.red.opacity(0.2) : Color.white.opacity(0.06)
        let soloFg: Color = layer.isSolo ? .yellow : AudioToyStyle.textMuted
        let soloBg: Color = layer.isSolo ? Color.yellow.opacity(0.2) : Color.white.opacity(0.06)

        return HStack(spacing: 4) {
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

            Button(action: {
                toggleSolo(layer: layer)
            }) {
                Text("S")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(soloFg)
                    .frame(width: 18, height: 18)
                    .background(soloBg)
                    .cornerRadius(3)
            }
            .buttonStyle(PlainButtonStyle())
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
