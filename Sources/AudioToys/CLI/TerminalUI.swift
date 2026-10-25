import Foundation

public final class TerminalUI: @unchecked Sendable {
    private let engine = SpatialAudioEngine()
    private var isRunning = true

    public init() {}

    public func runTheme(themeId: String? = nil, durationSeconds: Double? = nil) {
        // Ensure default samples exist
        let samplesDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources/Samples")
        SampleGenerator.generateDefaultSamples(inDirectory: samplesDir)

        let themesDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources/Themes")
        ThemeLoader.syncDefaultThemesToDisk(directory: themesDir)
        let themes = ThemeLoader.loadThemes(from: themesDir)

        let themeToPlay: Theme
        if let id = themeId, let found = themes.first(where: { $0.id == id }) {
            themeToPlay = found
        } else {
            themeToPlay = themes.first ?? ThemeLibrary.defaultThemes[0]
        }

        print("\u{001B}[2J\u{001B}[H") // Clear screen
        print("🎧 \u{001B}[1;36mAUDIOTOYS - Realtime 3D Spatial Audio\u{001B}[0m")
        print("Using Apple AVAudioEnvironmentNode (HRTFHQ Binaural 3D Audio)")
        print("────────────────────────────────────────────────────────────")
        print("▶️  Active Theme: \u{001B}[1;32m\(themeToPlay.title)\u{001B}[0m - \(themeToPlay.subtitle)")
        print("📝 \(themeToPlay.moodDescription)")
        print("🏛️  Reverb: \(themeToPlay.reverbPreset)")
        print("────────────────────────────────────────────────────────────\n")

        if let rev = ReverbEnvironmentPreset.allCases.first(where: { $0.rawValue == themeToPlay.reverbPreset }) {
            engine.currentReverb = rev
        }

        let layers = ThemeLoader.instantiate(theme: themeToPlay)
        for layer in layers {
            engine.addLayer(layer)
        }

        engine.start()

        let startTime = Date()
        var runLoopCounter = 0

        while isRunning {
            let elapsed = Date().timeIntervalSince(startTime)
            if let maxDuration = durationSeconds, elapsed >= maxDuration {
                break
            }

            // Update layer 3D positions each tick
            for layer in engine.activeLayers {
                layer.update(time: Float(elapsed))
            }

            if runLoopCounter % 3 == 0 {
                renderRadar(elapsed: elapsed)
            }

            runLoopCounter += 1
            Thread.sleep(forTimeInterval: 0.1)
        }

        engine.stop()
        print("\n⏹️ Playback ended.")
    }

    private func renderRadar(elapsed: Double) {
        // Render 21x21 ASCII radar grid
        let size = 15
        var grid = Array(repeating: Array(repeating: " ", count: size), count: size)

        let center = size / 2

        // Draw crosshair axes
        for x in 0..<size { grid[center][x] = "─" }
        for y in 0..<size { grid[y][center] = "│" }
        grid[center][center] = "🎧" // Listener center

        // Draw active layer markers
        for (idx, layer) in engine.activeLayers.enumerated() {
            // Map near-field meters (-0.85m to +0.85m) to grid
            let gx = Int(round(Float(center) + (layer.currentPosition.x / 0.85) * Float(center - 1)))
            let gz = Int(round(Float(center) + (layer.currentPosition.z / 0.85) * Float(center - 1)))

            if gx >= 0 && gx < size && gz >= 0 && gz < size {
                grid[gz][gx] = "\u{001B}[1;33m\(idx + 1)\u{001B}[0m"
            }
        }

        // Print header & grid in-place
        var output = "\u{001B}[7;1H" // Move cursor to line 7
        output += "         ▲ FRONT (Face)        Time: \(String(format: "%.1fs", elapsed))\n"
        for row in grid {
            output += "    " + row.joined() + "\n"
        }
        output += "         ▼ NAPE / BEHIND\n\n"

        output += "\u{001B}[1mActive Layers & 5-Stage Acoustic DSP Chains:\u{001B}[0m\n"
        for (idx, layer) in engine.activeLayers.enumerated() {
            let pos = layer.currentPosition
            let paddedName = layer.name.padding(toLength: 24, withPad: " ", startingAt: 0)
            output += String(format: " [\(idx + 1)] \u{001B}[1;36m%@\u{001B}[0m d:%3.0fcm (prox %3d%%) x:%+.2fm y:%+.2fm z:%+.2fm  [\(layer.filterChain.profile.rawValue)]\n",
                             paddedName, pos.magnitude * 100.0, layer.proximityPercent, pos.x, pos.y, pos.z)
        }

        print(output)
    }
}
