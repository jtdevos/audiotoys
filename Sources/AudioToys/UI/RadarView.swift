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
                    .allowsHitTesting(false)

                // Trails
                ForEach(appState.engine.activeLayers) { layer in
                    RadarTrailView(layer: layer, center: center, metersToPixels: metersToPixels)
                        .allowsHitTesting(false)
                }

                // Listener icon at center
                listenerMarker(center: center)
                    .allowsHitTesting(false)

                // Audio source nodes (each hit-tested strictly within its own node circle)
                ForEach(Array(appState.engine.activeLayers.enumerated()), id: \.element.id) { index, layer in
                    RadarNodeView(
                        layer: layer,
                        appState: appState,
                        index: index,
                        center: center,
                        metersToPixels: metersToPixels
                    )
                    .zIndex(appState.selectedLayerId == layer.id ? 100.0 : Double(index + 1))
                }

                // Top Radar Controls Bar
                VStack {
                    HStack(spacing: 8) {
                        // Scale Toggle
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.isNearFieldRadar.toggle()
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: appState.isNearFieldRadar ? "ear.and.waveform" : "circle.dashed")
                                    .font(.system(size: 10, weight: .bold))
                                Text(appState.isNearFieldRadar ? "NEAR-FIELD (1.0m)" : "ROOM SCALE (4.0m)")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(appState.isNearFieldRadar ? AudioToyStyle.accentEmerald : AudioToyStyle.accentCyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.78))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke((appState.isNearFieldRadar ? AudioToyStyle.accentEmerald : AudioToyStyle.accentCyan).opacity(0.45), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Freeze / Resume All Motion Toggle
                        Button(action: {
                            appState.toggleFreezeAllMotion()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: appState.areAllLayersPaused ? "play.circle.fill" : "pause.circle.fill")
                                    .font(.system(size: 10, weight: .bold))
                                Text(appState.areAllLayersPaused ? "RESUME ORBITS" : "FREEZE ORBITS")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(appState.areAllLayersPaused ? Color.orange : AudioToyStyle.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.78))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke((appState.areAllLayersPaused ? Color.orange : Color.white).opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()

                        // Compact vs Full Labels Toggle
                        Button(action: {
                            appState.showAllRadarTelemetry.toggle()
                        }) {
                            Text(appState.showAllRadarTelemetry ? "LABELS: FULL" : "LABELS: COMPACT")
                                .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(AudioToyStyle.textSecondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.65))
                                .cornerRadius(3)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(10)
                    Spacer()

                    // Bottom helper hint
                    HStack {
                        Text("CLICK TO SELECT • DRAG ANY NUMBERED NODE TO PLACE AROUND EARS")
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.38))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.55))
                            .cornerRadius(3)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                }
            }
            .coordinateSpace(name: "radarCanvas")
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
        let yawDeg = Double(appState.engine.listenerYawDegrees)
        return ZStack {
            // Subtle pulse ring
            Circle()
                .stroke(AudioToyStyle.accentCyan.opacity(0.35), lineWidth: 1.5)
                .frame(width: 44, height: 44)

            // Rotatable Head + AirPods + Nose indicator
            ZStack {
                // Head silhouette
                Circle()
                    .fill(Color(white: 0.16))
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.white.opacity(0.45), lineWidth: 1))

                // Forward nose indicator pointing to -Z (up on radar at 0° yaw)
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
            }
            .rotationEffect(.degrees(yawDeg))

            Text("YOU")
                .font(.system(size: 7, weight: .heavy, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.85))
        }
        .position(center)
    }
}

// MARK: - Observed Trail Subview

private struct RadarTrailView: View {
    @ObservedObject var layer: AudioLayer
    let center: CGPoint
    let metersToPixels: CGFloat

    var body: some View {
        let points = layer.recentTrail.map { pt in
            CGPoint(x: center.x + CGFloat(pt.x) * metersToPixels,
                    y: center.y + CGFloat(pt.z) * metersToPixels)
        }
        if points.count > 1 {
            Path { path in
                path.move(to: points[0])
                for pt in points.dropFirst() {
                    path.addLine(to: pt)
                }
            }
            .stroke(Color(hex: layer.colorHex).opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
        }
    }
}

// MARK: - Observed Interactive Node Subview

private struct RadarNodeView: View {
    @ObservedObject var layer: AudioLayer
    @ObservedObject var appState: AppState
    let index: Int
    let center: CGPoint
    let metersToPixels: CGFloat

    @State private var isHovered: Bool = false
    @State private var isDragging: Bool = false

    var body: some View {
        let nodePos = CGPoint(
            x: center.x + CGFloat(layer.currentPosition.x) * metersToPixels,
            y: center.y + CGFloat(layer.currentPosition.z) * metersToPixels
        )
        let isSelected = appState.selectedLayerId == layer.id
        let showDetails = isSelected || isHovered || appState.showAllRadarTelemetry
        let color = Color(hex: layer.colorHex)
        let isPinned = layer.motionScript.type == .fixed || layer.isMotionPaused

        ZStack {
            // Real-time audio waveform envelope glow aura
            Circle()
                .fill(color.opacity(Double(0.18 + layer.activityLevel * 0.55)))
                .frame(width: CGFloat(28 + layer.activityLevel * 28),
                       height: CGFloat(28 + layer.activityLevel * 28))
                .blur(radius: 6)
                .allowsHitTesting(false)

            // Selection / hover halo
            if isSelected || isHovered {
                Circle()
                    .stroke(Color.white.opacity(isSelected ? 0.9 : 0.45), lineWidth: isSelected ? 2.5 : 1.5)
                    .frame(width: 28, height: 28)
                    .allowsHitTesting(false)
            }

            // Outer ring
            Circle()
                .fill(Color.black.opacity(0.75))
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.white : color, lineWidth: isSelected ? 2.0 : 1.5)
                )

            // Core dot with layer index number
            Circle()
                .fill(layer.isMuted ? Color.gray.opacity(0.5) : color)
                .frame(width: 16, height: 16)
                .overlay(
                    Text("\(index + 1)")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(.black)
                )

            // Pinned indicator badge at top-right of node
            if isPinned {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
                    .offset(x: 9, y: -9)
                    .allowsHitTesting(false)
            }

            // Name label & Proximity/Distance readout (non-hit-tested so labels don't block adjacent nodes)
            VStack(spacing: 1) {
                Text(layer.name)
                    .font(.system(size: isSelected ? 9.5 : 8.5, weight: isSelected ? .bold : .medium, design: .monospaced))
                    .foregroundColor(isSelected ? Color.white : Color.white.opacity(0.82))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1.5)
                    .background(Color.black.opacity(isSelected ? 0.88 : 0.68))
                    .cornerRadius(3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(isSelected ? color.opacity(0.7) : Color.clear, lineWidth: 1)
                    )

                if showDetails {
                    Text(String(format: "%.0fcm • prox %d%%", layer.currentPosition.magnitude * 100.0, layer.proximityPercent))
                        .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(layer.proximityPercent > 35 ? AudioToyStyle.accentEmerald : AudioToyStyle.accentCyan.opacity(0.9))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.black.opacity(0.82))
                        .cornerRadius(2)
                }
            }
            .offset(y: showDetails ? 25 : 20)
            .allowsHitTesting(false)
        }
        // IMPORTANT: Attach frame, contentShape, hover, tap, and drag BEFORE .position(nodePos)
        // so hit-testing is strictly confined to this 38x38 node circle!
        .frame(width: 38, height: 38)
        .contentShape(Circle())
        .scaleEffect(isDragging ? 1.15 : 1.0)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            appState.selectLayer(withId: layer.id)
        }
        .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .named("radarCanvas"))
                .onChanged { value in
                    isDragging = true
                    let newX = Float((value.location.x - center.x) / metersToPixels)
                    let newZ = Float((value.location.y - center.y) / metersToPixels)
                    let updatedPos = Vector3(newX, layer.currentPosition.y, newZ)
                    appState.pinLayer(layer, at: updatedPos)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
        .position(nodePos)
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
