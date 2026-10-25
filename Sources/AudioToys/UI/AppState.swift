import Foundation
import SwiftUI

/// Central observable application state for AudioToys
public final class AppState: ObservableObject, @unchecked Sendable {
    public let engine = SpatialAudioEngine()

    @Published public var themes: [Theme] = ThemeLibrary.defaultThemes
    @Published public var selectedThemeId: String = "barber-shop"
    @Published public var selectedLayerId: String? = nil

    @Published public var isNearFieldRadar: Bool = true
    @Published public var scriptEditorText: String = ""
    @Published public var scriptStatus: String = "Ready"
    @Published public var isScriptError: Bool = false

    public init() {
        setupState()
    }

    public func setupState() {
        // Ensure default samples exist
        let samplesDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources/Samples")
        SampleGenerator.generateDefaultSamples(inDirectory: samplesDir)

        // Sync and load themes
        let themesDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources/Themes")
        ThemeLoader.syncDefaultThemesToDisk(directory: themesDir)
        self.themes = ThemeLoader.loadThemes(from: themesDir)

        if let defaultTheme = themes.first(where: { $0.id == selectedThemeId }) ?? themes.first {
            loadTheme(defaultTheme)
        }

        // Start audio engine
        engine.start()
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
        }
    }

    public func selectLayer(withId id: String) {
        selectedLayerId = id
        if let layer = engine.activeLayers.first(where: { $0.id == id }) {
            scriptEditorText = layer.motionScript.rawScript
            scriptStatus = "Active: \(layer.motionScript.type.rawValue)"
            isScriptError = false
        }
    }

    public func applyScriptToSelectedLayer(_ scriptStr: String) {
        guard let layerId = selectedLayerId,
              let layer = engine.activeLayers.first(where: { $0.id == layerId }) else {
            return
        }
        let script = MotionScript()
        script.parse(script: scriptStr)
        layer.motionScript = script
        layer.recentTrail.removeAll()
        scriptEditorText = scriptStr
        scriptStatus = "Running: \(script.type.rawValue)"
        isScriptError = false
    }
}
