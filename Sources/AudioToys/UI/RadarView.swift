import SwiftUI

public struct RadarView: View {
    @ObservedObject var appState: AppState

    private let metersToPixels: CGFloat = 52.0
    private let maxMeterRadius: Float = 4.0

    public var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2.0, y: geo.size.height / 2.0)

            ZStack {
                // Background radar grid
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
            }
            .contentShape(Rectangle())
        }
    }

    // MARK: - Radar Grid

    private func radarGrid(center: CGPoint, size: CGSize) -> some View {
        ZStack {
            // Distance rings: 1m, 2m, 3m, 4m
            ForEach([1.0, 2.0, 3.0, 4.0], id: \.self) { r in
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    .frame(width: CGFloat(r * 2.0) * metersToPixels,
                           height: CGFloat(r * 2.0) * metersToPixels)
                    .position(center)

                // Range label
                Text(String(format: "%.0fm", r))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.25))
                    .position(x: center.x + CGFloat(r) * metersToPixels - 12, y: center.y - 8)
            }

            // Crosshair lines
            Path { path in
                path.move(to: CGPoint(x: center.x, y: center.y - 4.2 * metersToPixels))
                path.addLine(to: CGPoint(x: center.x, y: center.y + 4.2 * metersToPixels))
                path.move(to: CGPoint(x: center.x - 4.2 * metersToPixels, y: center.y))
                path.addLine(to: CGPoint(x: center.x + 4.2 * metersToPixels, y: center.y))
            }
            .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            // Cardinal direction labels
            Text("FRONT (NOSE)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(AudioToyStyle.accentCyan.opacity(0.7))
                .position(x: center.x, y: center.y - 4.2 * metersToPixels - 14)

            Text("BEHIND")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.3))
                .position(x: center.x, y: center.y + 4.2 * metersToPixels + 14)

            Text("LEFT")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.3))
                .position(x: center.x - 4.2 * metersToPixels - 20, y: center.y)

            Text("RIGHT")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.3))
                .position(x: center.x + 4.2 * metersToPixels + 22, y: center.y)
        }
    }

    // MARK: - Listener Marker (Center)

    private func listenerMarker(center: CGPoint) -> some View {
        ZStack {
            // Subtle pulse ring
            Circle()
                .stroke(AudioToyStyle.accentCyan.opacity(0.3), lineWidth: 1.5)
                .frame(width: 38, height: 38)

            // Head silhouette
            Circle()
                .fill(Color(white: 0.18))
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))

            // Forward nose indicator pointing to -Z (up on radar)
            Triangle()
                .fill(AudioToyStyle.accentCyan)
                .frame(width: 8, height: 6)
                .offset(y: -13)

            // Left & Right AirPods Pro icons
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.white)
                .frame(width: 3, height: 7)
                .offset(x: -12, y: 0)

            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.white)
                .frame(width: 3, height: 7)
                .offset(x: 12, y: 0)

            Text("YOU")
                .font(.system(size: 7, weight: .heavy, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.8))
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
            .stroke(Color(hex: layer.colorHex).opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
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
            // Glow aura
            Circle()
                .fill(color.opacity(Double(0.15 + layer.activityLevel * 0.45)))
                .frame(width: CGFloat(30 + layer.activityLevel * 20),
                       height: CGFloat(30 + layer.activityLevel * 20))
                .blur(radius: 6)

            // Outer ring
            Circle()
                .stroke(isSelected ? Color.white : color, lineWidth: isSelected ? 2.5 : 1.5)
                .frame(width: 20, height: 20)

            // Core dot
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            // Name label & Height indicator
            VStack(spacing: 2) {
                Text(layer.name)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(3)

                Text(String(format: "y: %+.1fm", layer.currentPosition.y))
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .foregroundColor(AudioToyStyle.accentCyan.opacity(0.9))
            }
            .offset(y: 24)
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
