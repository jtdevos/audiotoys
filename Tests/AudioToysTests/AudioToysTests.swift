import Foundation
import Testing
@testable import AudioToys

@Test func deterministicLayerDefinitionIds() throws {
    let def1 = LayerDefinition(
        name: "Japanese Steel Shears",
        colorHex: "#00F5D4",
        volume: 0.88,
        source: .procedural(.granularImpulse(type: "scissors", density: 3.5)),
        motionScript: "orbit radius=0.26 speed=0.11"
    )
    let def2 = LayerDefinition(
        name: "Japanese Steel Shears",
        colorHex: "#00F5D4",
        volume: 0.88,
        source: .procedural(.granularImpulse(type: "scissors", density: 3.5)),
        motionScript: "orbit radius=0.26 speed=0.11"
    )
    #expect(def1.id == "japanese-steel-shears")
    #expect(def1.id == def2.id)
}

@Test func themeLoaderDoesNotOverwriteExistingFilesOnSync() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("audiotoys-test-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: tempDir) }

    ThemeLoader.syncDefaultThemesToDisk(directory: tempDir, overwriteExisting: true)
    let barberUrl = tempDir.appendingPathComponent("barber-shop.json")
    #expect(FileManager.default.fileExists(atPath: barberUrl.path))

    // Modify the theme on disk and save
    var themes = ThemeLoader.loadThemes(from: tempDir)
    var barber = try #require(themes.first(where: { $0.id == "barber-shop" }))
    barber.subtitle = "Custom User Subtitle"
    #expect(ThemeLoader.saveTheme(barber, to: tempDir))

    // Syncing with overwriteExisting: false should preserve the custom subtitle
    ThemeLoader.syncDefaultThemesToDisk(directory: tempDir, overwriteExisting: false)
    themes = ThemeLoader.loadThemes(from: tempDir)
    let reloaded = try #require(themes.first(where: { $0.id == "barber-shop" }))
    #expect(reloaded.subtitle == "Custom User Subtitle")

    // Resetting restores the default subtitle
    let reset = try #require(ThemeLoader.resetTheme(withId: "barber-shop", in: tempDir))
    #expect(reset.subtitle != "Custom User Subtitle")
}

@Test func layerPinAndResumeMotion() throws {
    let initialOrbit = MotionScript.orbit(radius: 0.30, speed: 0.15, height: 0.05)
    let layer = AudioLayer(
        id: "shears",
        name: "Japanese Steel Shears",
        source: .procedural(.granularImpulse(type: "scissors", density: 3.5)),
        motionScript: initialOrbit
    )
    #expect(layer.motionScript.type == .orbit)
    #expect(layer.savedMotionScriptBeforePin != nil)

    // Pin the layer by dragging it to (-0.25, 0.05, 0.10)
    layer.pinAt(Vector3(-0.25, 0.05, 0.10))
    #expect(layer.motionScript.type == .fixed)
    #expect(abs(layer.currentPosition.x - (-0.25)) < 0.01)
    #expect(abs(layer.currentPosition.z - 0.10) < 0.01)

    // Resuming restores the saved orbit trajectory
    layer.resumeSavedMotion()
    #expect(layer.motionScript.type == .orbit)
    #expect(abs(layer.motionScript.radius - 0.30) < 0.01)
}

@Test func motionScriptDirectSliderUpdates() throws {
    let script = MotionScript.orbit(radius: 0.25, speed: 0.12, height: 0.0)
    script.updateRadius(0.45)
    script.updateSpeed(0.30)
    script.updateElevation(0.18)

    #expect(abs(script.effectiveRadius - 0.45) < 0.01)
    #expect(abs(script.effectiveSpeed - 0.30) < 0.01)
    #expect(abs(script.effectiveElevation - 0.18) < 0.01)
    #expect(script.rawScript.contains("radius=0.45"))
}

@Test func layerTriggerIntervalAndCrossThemeMixing() throws {
    let coughLayer = AudioLayer(
        id: "cough",
        name: "Occasional Distant Cough",
        source: .audioFile(path: "Resources/Samples/classroom_cough.wav", isLooping: false, interval: 18.0),
        motionScript: MotionScript.fixed(at: Vector3(-0.7, 0, 0.4))
    )
    #expect(coughLayer.isPeriodicOrTriggerable == true)
    #expect(coughLayer.triggerInterval == 18.0)

    coughLayer.updateTriggerInterval(6.5)
    #expect(coughLayer.triggerInterval == 6.5)

    let state = AppState(autoStartEngine: false)
    let initialCount = state.engine.activeLayers.count
    let catalog = state.availableCatalogLayers
    #expect(!catalog.isEmpty)

    let extraDef = try #require(catalog.first)
    state.addLayerFromCatalog(extraDef)
    #expect(state.engine.activeLayers.count == initialCount + 1)

    if let addedId = state.selectedLayerId {
        state.removeLayer(withId: addedId)
        #expect(state.engine.activeLayers.count == initialCount)
    }
}

@Test func headphoneOrientationAndRecenter() throws {
    let engine = SpatialAudioEngine()
    #expect(engine.listenerYawDegrees == 0.0)

    engine.updateListenerOrientation(yawDegrees: 35.0, pitchDegrees: -5.0, rollDegrees: 2.0)
    #expect(abs(engine.listenerYawDegrees - 35.0) < 0.01)
    #expect(abs(engine.environmentNode.listenerAngularOrientation.yaw - 35.0) < 0.01)

    engine.recenterHeadOrientation()
    #expect(abs(engine.listenerYawDegrees) < 0.01)
    #expect(abs(engine.environmentNode.listenerAngularOrientation.yaw) < 0.01)
}



