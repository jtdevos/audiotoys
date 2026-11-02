import Foundation
import SwiftUI
import Combine

/// Central observable application state for AudioToys
public final class AppState: ObservableObject, @unchecked Sendable {
    public let engine = SpatialAudioEngine()

    @Published public var themes: [Theme] = ThemeLibrary.defaultThemes
    @Published public var selectedThemeId: String = "barber-shop"
    @Published public var selectedLayerId: String? = nil

    @Published public var isNearFieldRadar: Bool = true
    @Published public var showAllRadarTelemetry: Bool = false
    @Published public var scriptEditorText: String = ""
    @Published public var scriptStatus: String = "Ready"
    @Published public var isScriptError: Bool = false

    private var engineCancellable: AnyCancellable?

    public init(autoStartEngine: Bool = true) {
        engineCancellable = engine.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        setupState(autoStartEngine: autoStartEngine)
    }

    public var themesDirectoryURL: URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources/Themes")
    }

    public func setupState(autoStartEngine: Bool = true) {
        // Ensure default samples exist
        let samplesDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources/Samples")
        SampleGenerator.generateDefaultSamples(inDirectory: samplesDir)

        // Sync missing default themes (without overwriting existing JSON files) and load themes
        let themesDir = themesDirectoryURL
        ThemeLoader.syncDefaultThemesToDisk(directory: themesDir, overwriteExisting: false)
        self.themes = ThemeLoader.loadThemes(from: themesDir)

        if let defaultTheme = themes.first(where: { $0.id == selectedThemeId }) ?? themes.first {
            loadTheme(defaultTheme)
        }

        if autoStartEngine {
            engine.start()
        }
    }

    public func selectTheme(withId id: String) {
        selectedThemeId = id
        if let theme = themes.first(where: { $0.id == id }) {
            loadTheme(theme)
        }
    }

    public func loadTheme(_ theme: Theme) {
        engine.removeAllLayers()

        if let rev = ReverbEnvironmentPreset.allCases.first(where: { $0.rawValue == theme.reverbPreset }) {
            engine.currentReverb = rev
        }

        let layers = ThemeLoader.instantiate(theme: theme)
        for layer in layers {
            engine.addLayer(layer)
        }

        selectedLayerId = layers.first?.id
        if let firstLayer = layers.first {
            scriptEditorText = firstLayer.motionScript.rawScript
            scriptStatus = "Active: \(firstLayer.motionScript.type.rawValue)"
            isScriptError = false
        }
    }

    public func selectLayer(withId id: String) {
        selectedLayerId = id
        if let layer = engine.activeLayers.first(where: { $0.id == id }) {
            scriptEditorText = layer.motionScript.rawScript
            scriptStatus = layer.isMotionPaused ? "Paused" : "Active: \(layer.motionScript.type.rawValue)"
            isScriptError = false
        }
    }

    public func pinLayer(_ layer: AudioLayer, at pos: Vector3) {
        if selectedLayerId != layer.id {
            selectedLayerId = layer.id
        }
        layer.pinAt(pos)
        scriptEditorText = layer.motionScript.rawScript
        scriptStatus = "Pinned at (\(String(format: "%.2f, %.2f", pos.x, pos.z)))"
        isScriptError = false
        objectWillChange.send()
    }

    public var areAllLayersPaused: Bool {
        !engine.activeLayers.isEmpty && engine.activeLayers.allSatisfy { $0.isMotionPaused || $0.motionScript.type == .fixed }
    }

    public func toggleFreezeAllMotion() {
        let shouldPause = !areAllLayersPaused
        for layer in engine.activeLayers {
            layer.isMotionPaused = shouldPause
            layer.objectWillChange.send()
        }
        scriptStatus = shouldPause ? "All motion paused" : "Motion resumed"
        objectWillChange.send()
    }

    public func applyScriptToSelectedLayer(_ scriptStr: String) {
        guard let layerId = selectedLayerId,
              let layer = engine.activeLayers.first(where: { $0.id == layerId }) else {
            return
        }
        let script = MotionScript()
        script.parse(script: scriptStr)
        if script.type != .fixed {
            layer.savedMotionScriptBeforePin = script.rawScript
        }
        layer.isMotionPaused = false
        layer.motionScript = script
        layer.recentTrail.removeAll()
        layer.syncSpatialPosition(script.position(at: engine.elapsedTime))
        layer.objectWillChange.send()
        scriptEditorText = script.rawScript
        scriptStatus = "Running: \(script.type.rawValue)"
        isScriptError = false
        objectWillChange.send()
    }

    public func saveCurrentTheme() {
        guard let idx = themes.firstIndex(where: { $0.id == selectedThemeId }) else { return }
        let updated = ThemeLoader.captureTheme(
            base: themes[idx],
            activeLayers: engine.activeLayers,
            reverb: engine.currentReverb
        )
        themes[idx] = updated
        if ThemeLoader.saveTheme(updated, to: themesDirectoryURL) {
            scriptStatus = "Saved \(updated.title)"
            isScriptError = false
        }
    }

    public func resetCurrentTheme() {
        if let restored = ThemeLoader.resetTheme(withId: selectedThemeId, in: themesDirectoryURL) {
            if let idx = themes.firstIndex(where: { $0.id == selectedThemeId }) {
                themes[idx] = restored
            }
            loadTheme(restored)
            scriptStatus = "Reset to default"
        }
    }
}
