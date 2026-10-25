import SwiftUI

public struct RadarView: View {
    @ObservedObject var appState: AppState

    private var metersToPixels: CGFloat {
        appState.isNearFieldRadar ? 185.0 : 54.0
    }

    private var ringRadii: [Double] {
        appState.isNearFieldRadar ? [0.20, 0.40, 0.65, 1.00] : [1.0, 2.0, 3.0, 4.0]
    }

    public var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2.0, y: geo.size.height / 2.0)

            ZStack {
                // Background radar grid & ASMR proximity zone
                radarGrid(center: center, size: geo.size)

                // Trails
                ForEach(appState.engine.activeLayers) { layer in
                    trailView(layer: layer, center: center)
                }

                // Listener icon at center
                listenerMarker(center: center)

                // Audio source nodes
                ForEach(appState.engine.activeLayers) { layer in
                    sourceNodeView(layer: layer, center: center)
                }

                // Top-left Radar Scale Toggle & ASMR Proximity Indicator
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.isNearFieldRadar.toggle()
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: appState.isNearFieldRadar ? "ear.and.waveform" : "circle.dashed")
                                    .font(.system(size: 10, weight: .bold))
                                Text(appState.isNearFieldRadar ? "SCALE: NEAR-FIELD ASMR (1.0m)" : "SCALE: ROOM (4.0m)")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(appState.isNearFieldRadar ? AudioToyStyle.accentEmerald : AudioToyStyle.accentCyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.75))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke((appState.isNearFieldRadar ? AudioToyStyle.accentEmerald : AudioToyStyle.accentCyan).opacity(0.45), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()

                        Text("DRAG NODES AROUND EARS")
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.35))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(3)
                    }
                    .padding(10)
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .clipped()
        }
    }

    // MARK: - Radar Grid

    private func radarGrid(center: CGPoint, size: CGSize) -> some View {
        let maxR = ringRadii.last ?? 1.0
        return ZStack {
            // Subtle warm ASMR Proximity Zone glow inside 0.40m
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            AudioToyStyle.accentEmerald.opacity(0.10),
                            AudioToyStyle.accentCyan.opacity(0.03),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 4,
                        endRadius: CGFloat(0.42) * metersToPixels
                    )
                )
                .frame(width: CGFloat(0.84) * metersToPixels,
                       height: CGFloat(0.84) * metersToPixels)
                .position(center)

            // Distance rings
            ForEach(ringRadii, id: \.self) { r in
                let isASMRRing = abs(r - 0.20) < 0.01 || abs(r - 0.40) < 0.01
                Circle()
                    .stroke(
                        isASMRRing ? AudioToyStyle.accentEmerald.opacity(0.22) : Color.white.opacity(0.08),
                        style: StrokeStyle(lineWidth: 1, dash: abs(r - 0.20) < 0.01 ? [3, 3] : [])
                    )
                    .frame(width: CGFloat(r * 2.0) * metersToPixels,
                           height: CGFloat(r * 2.0) * metersToPixels)
                    .position(center)

                // Range label
                Text(r < 1.0 ? String(format: "%.0fcm", r * 100.0) : String(format: "%.1fm", r))
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(isASMRRing ? AudioToyStyle.accentEmerald.opacity(0.55) : Color.white.opacity(0.25))
                    .position(x: center.x + CGFloat(r) * metersToPixels - 14, y: center.y - 8)
            }

            // Crosshair lines
            let lineExtent = CGFloat(maxR * 1.06) * metersToPixels
            Path { path in
                path.move(to: CGPoint(x: center.x, y: center.y - lineExtent))
                path.addLine(to: CGPoint(x: center.x, y: center.y + lineExtent))
                path.move(to: CGPoint(x: center.x - lineExtent, y: center.y))
                path.addLine(to: CGPoint(x: center.x + lineExtent, y: center.y))
            }
            .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            // Cardinal direction labels
            Text("FRONT (FACE)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(AudioToyStyle.accentCyan.opacity(0.75))
                .position(x: center.x, y: center.y - lineExtent - 12)

            Text("NAPE / BEHIND HEAD")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.35))
                .position(x: center.x, y: center.y + lineExtent + 12)

            Text("LEFT EAR")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.35))
                .position(x: center.x - lineExtent - 28, y: center.y)

            Text("RIGHT EAR")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.35))
                .position(x: center.x + lineExtent + 30, y: center.y)
        }
    }

    // MARK: - Listener Marker (Center)

    private func listenerMarker(center: CGPoint) -> some View {
        ZStack {
            // Subtle pulse ring
            Circle()
                .stroke(AudioToyStyle.accentCyan.opacity(0.35), lineWidth: 1.5)
                .frame(width: 44, height: 44)

            // Head silhouette
            Circle()
                .fill(Color(white: 0.16))
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(Color.white.opacity(0.45), lineWidth: 1))

            // Forward nose indicator pointing to -Z (up on radar)
            Triangle()
                .fill(AudioToyStyle.accentCyan)
                .frame(width: 8, height: 6)
                .offset(y: -16)

            // Left & Right AirPods Pro icons
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 4, height: 9)
                .offset(x: -16, y: 0)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 4, height: 9)
                .offset(x: 16, y: 0)

            Text("YOU")
                .font(.system(size: 7, weight: .heavy, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.85))
        }
        .position(center)
    }

    // MARK: - Node Trails

    private func trailView(layer: AudioLayer, center: CGPoint) -> some View {
        let points = layer.recentTrail.map { pt in
            CGPoint(x: center.x + CGFloat(pt.x) * metersToPixels,
                    y: center.y + CGFloat(pt.z) * metersToPixels)
        }
        guard points.count > 1 else { return AnyView(EmptyView()) }

        return AnyView(
            Path { path in
                path.move(to: points[0])
                for pt in points.dropFirst() {
                    path.addLine(to: pt)
                }
            }
            .stroke(Color(hex: layer.colorHex).opacity(0.38), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
        )
    }

    // MARK: - Audio Source Node View

    private func sourceNodeView(layer: AudioLayer, center: CGPoint) -> some View {
        let nodePos = CGPoint(
            x: center.x + CGFloat(layer.currentPosition.x) * metersToPixels,
            y: center.y + CGFloat(layer.currentPosition.z) * metersToPixels
        )
        let isSelected = appState.selectedLayerId == layer.id
        let color = Color(hex: layer.colorHex)

        return ZStack {
            // Real-time audio waveform envelope glow aura
            Circle()
                .fill(color.opacity(Double(0.18 + layer.activityLevel * 0.55)))
                .frame(width: CGFloat(28 + layer.activityLevel * 28),
                       height: CGFloat(28 + layer.activityLevel * 28))
                .blur(radius: 6)

            // Outer ring
            Circle()
                .stroke(isSelected ? Color.white : color, lineWidth: isSelected ? 2.5 : 1.5)
                .frame(width: 20, height: 20)

            // Core dot
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            // Name label & Proximity/Distance readout
            VStack(spacing: 1) {
                Text(layer.name)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1.5)
                    .background(Color.black.opacity(0.78))
                    .cornerRadius(3)

                Text(String(format: "%.0fcm • prox %d%%", layer.currentPosition.magnitude * 100.0, layer.proximityPercent))
                    .font(.system(size: 7.5, weight: .medium, design: .monospaced))
                    .foregroundColor(layer.proximityPercent > 35 ? AudioToyStyle.accentEmerald : AudioToyStyle.accentCyan.opacity(0.85))
            }
            .offset(y: 23)
        }
        .position(nodePos)
        .gesture(
            DragGesture()
                .onChanged { value in
                    appState.selectedLayerId = layer.id
                    let newX = Float((value.location.x - center.x) / metersToPixels)
                    let newZ = Float((value.location.y - center.y) / metersToPixels)
                    let updatedPos = Vector3(newX, layer.currentPosition.y, newZ)
                    layer.currentPosition = updatedPos
                    layer.motionScript = MotionScript.fixed(at: updatedPos)
                    appState.scriptEditorText = "static x=\(String(format: "%.2f", newX)) y=\(String(format: "%.2f", layer.currentPosition.y)) z=\(String(format: "%.2f", newZ))"
                }
        )
        .onTapGesture {
            appState.selectLayer(withId: layer.id)
        }
    }
}

// Helper Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
