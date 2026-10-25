import Foundation
import AVFoundation

public enum ReverbEnvironmentPreset: String, CaseIterable, Identifiable {
    case smallRoom = "Small Room"
    case mediumRoom = "Medium Room"
    case largeChamber = "Large Chamber"
    case cathedral = "Cathedral"
    case plate = "Plate Reverb"
    case off = "Direct (No Reverb)"

    public var id: String { rawValue }

    public var avPreset: AVAudioUnitReverbPreset? {
        switch self {
        case .cathedral: return .cathedral
        case .largeChamber: return .largeChamber
        case .mediumRoom: return .mediumRoom
        case .plate: return .plate
        case .smallRoom: return .smallRoom
        case .off: return nil
        }
    }
}

/// The spatial audio engine managing AVAudioEngine, AVAudioEnvironmentNode,
/// real-time HRTF 3D spatialization, 5-stage per-layer acoustic filter chains,
/// and organic sample/procedural rendering.
public final class SpatialAudioEngine: ObservableObject, @unchecked Sendable {
    public let engine = AVAudioEngine()
    public let environmentNode = AVAudioEnvironmentNode()

    @Published public private(set) var isRunning: Bool = false
    @Published public var masterVolume: Float = 0.88 {
        didSet {
            engine.mainMixerNode.outputVolume = masterVolume
        }
    }
    @Published public var currentReverb: ReverbEnvironmentPreset = .smallRoom {
        didSet {
            applyReverb(currentReverb)
        }
    }
    @Published public var asmrProximityBoost: Float = 1.0 {
        didSet {
            for layer in activeLayers {
                layer.filterChain.proximityIntensity = asmrProximityBoost
            }
        }
    }

    @Published public private(set) var activeLayers: [AudioLayer] = []
    @Published public private(set) var elapsedTime: Float = 0.0

    private var displayTimer: Timer?
    private let startTime: Date = Date()
    private let standardFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)!

    public init() {
        setupEngine()
    }

    private func setupEngine() {
        engine.attach(environmentNode)

        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let envFormat = AVAudioFormat(
            standardFormatWithSampleRate: outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 44100.0,
            channels: 2
        )!

        engine.connect(environmentNode, to: engine.mainMixerNode, format: envFormat)

        // Apple High-Quality HRTF binaural spatial rendering for AirPods Pro & headphones
        environmentNode.renderingAlgorithm = .HRTFHQ
        environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        environmentNode.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: 0, pitch: 0, roll: 0)

        // Calibrated for both near-field ASMR (0.15m - 0.8m) and room-scale (1.0m - 6.0m)
        environmentNode.distanceAttenuationParameters.distanceAttenuationModel = .inverse
        environmentNode.distanceAttenuationParameters.referenceDistance = 0.32
        environmentNode.distanceAttenuationParameters.maximumDistance = 25.0
        environmentNode.distanceAttenuationParameters.rolloffFactor = 0.78

        applyReverb(currentReverb)
        engine.mainMixerNode.outputVolume = masterVolume
    }

    public func applyReverb(_ preset: ReverbEnvironmentPreset) {
        if let avPre = preset.avPreset {
            environmentNode.reverbParameters.enable = true
            environmentNode.reverbParameters.loadFactoryReverbPreset(avPre)
            // Subtle, natural acoustic room reflection level (avoids metallic ringing)
            switch preset {
            case .smallRoom:
                environmentNode.reverbParameters.level = -24.0
            case .mediumRoom:
                environmentNode.reverbParameters.level = -21.0
            case .largeChamber:
                environmentNode.reverbParameters.level = -18.0
            case .cathedral:
                environmentNode.reverbParameters.level = -15.0
            case .plate:
                environmentNode.reverbParameters.level = -19.0
            case .off:
                environmentNode.reverbParameters.enable = false
            }
        } else {
            environmentNode.reverbParameters.enable = false
        }
    }

    public func start() {
        guard !isRunning else { return }
        do {
            try engine.start()
            isRunning = true
            startUpdateTimer()
            print("🔊 SpatialAudioEngine started (HRTFHQ Binaural + 5-Stage Acoustic Filter Chain).")
        } catch {
            print("❌ Failed to start AVAudioEngine: \(error)")
        }
    }

    public func stop() {
        guard isRunning else { return }
        displayTimer?.invalidate()
        displayTimer = nil
        engine.stop()
        isRunning = false
        print("SpatialAudioEngine stopped.")
    }

    // MARK: - Layer Management

    public func removeAllLayers() {
        for layer in activeLayers {
            if let node = layer.audioNode {
                if let player = layer.playerNode {
                    player.stop()
                }
                engine.disconnectNodeOutput(node)
                engine.detach(node)
            }
        }
        activeLayers.removeAll()
    }

    public func addLayer(_ layer: AudioLayer) {
        let isEngineRunning = engine.isRunning
        layer.filterChain.proximityIntensity = asmrProximityBoost

        let resolvedVoice: DSPVoice?
        switch layer.source {
        case .procedural(let config):
            resolvedVoice = createDSPVoice(for: config)

        case .audioFile(let path, let isLooping, let interval):
            let fileURL = resolveResourceURL(path: path)
            if let streamer = OrganicSampleStreamer(fileURL: fileURL, isLooping: isLooping, interval: interval) {
                resolvedVoice = streamer
            } else {
                print("⚠️ Could not load audio file at: \(fileURL.path)")
                resolvedVoice = nil
            }
        }

        guard let voice = resolvedVoice else { return }
        layer.dspVoice = voice
        let sampleRate = standardFormat.sampleRate
        let filterChain = layer.filterChain

        let sourceNode = AVAudioSourceNode(format: standardFormat) { [weak layer] _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let buffer = abl[0].mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            let frames = Int(frameCount)
            memset(buffer, 0, frames * MemoryLayout<Float>.size)

            guard let l = layer, !l.isMuted, l.volume > 0.0001 else {
                return noErr
            }

            // 1. Render raw organic sample or physical/modal voice
            voice.render(buffer: buffer, frameCount: frames, sampleRate: sampleRate)

            // 2. Process through 5-stage acoustic filter chain (HPF -> Proximity Shelf -> Body EQ -> Air Exciter/LPF -> Transient/SoftClip)
            filterChain.process(buffer: buffer, frameCount: frames, sampleRate: sampleRate)

            // 3. Apply layer volume
            let vol = l.volume
            if abs(vol - 1.0) > 0.001 {
                for i in 0..<frames {
                    buffer[i] *= vol
                }
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: environmentNode, format: standardFormat)
        layer.audioNode = sourceNode

        // Configure 3D HRTF mixing
        sourceNode.renderingAlgorithm = .HRTFHQ
        let initialPos = layer.currentPosition
        let dist = initialPos.magnitude
        sourceNode.reverbBlend = max(0.02, min(0.35, (dist - 0.18) * 0.14))
        sourceNode.position = AVAudio3DPoint(x: initialPos.x, y: initialPos.y, z: initialPos.z)

        layer.environmentNode = environmentNode
        activeLayers.append(layer)

        if isEngineRunning && !engine.isRunning {
            try? engine.start()
        }
    }

    private func resolveResourceURL(path: String) -> URL {
        if path.starts(with: "/") {
            return URL(fileURLWithPath: path)
        }
        let cwdURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(path)
        if FileManager.default.fileExists(atPath: cwdURL.path) {
            return cwdURL
        }
        if let bundleResURL = Bundle.main.resourceURL {
            let candidate1 = bundleResURL.appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: candidate1.path) {
                return candidate1
            }
            let candidate2 = bundleResURL.appendingPathComponent("Resources").appendingPathComponent(
                path.replacingOccurrences(of: "Resources/", with: "")
            )
            if FileManager.default.fileExists(atPath: candidate2.path) {
                return candidate2
            }
        }
        return cwdURL
    }

    private func createDSPVoice(for config: ProceduralVoiceConfig) -> DSPVoice {
        switch config {
        case .fmBell(let baseFreq, let modRatio, let interval):
            let voice = FMBellVoice(baseFreq: baseFreq, modRatio: modRatio)
            voice.autoTriggerInterval = interval
            return voice

        case .pluckedString(let baseFreq, let interval):
            let voice = PluckedStringVoice()
            voice.baseFreq = baseFreq
            voice.autoTriggerInterval = interval
            return voice

        case .filteredNoise(let typeStr, let cutoff, let resonance):
            let nType: FilteredNoiseVoice.NoiseType
            switch typeStr.lowercased() {
            case "brown": nType = .brown
            case "white": nType = .white
            default: nType = .pink
            }
            return FilteredNoiseVoice(type: nType, cutoff: cutoff, resonance: resonance)

        case .granularImpulse(let typeStr, let density):
            let iType: GranularImpulseVoice.ImpulseType
            switch typeStr.lowercased() {
            case "campfire": iType = .campfire
            case "clocktick": iType = .clockTick
            case "scissors", "barberscissors": iType = .barberScissors
            case "comb", "barbercomb": iType = .barberComb
            default: iType = .raindrop
            }
            return GranularImpulseVoice(type: iType, density: density)

        case .subtractiveDrone(let fundamental, let detune):
            let voice = SubtractiveDroneVoice(fundamental: fundamental)
            voice.detuneCents = detune
            return voice

        case .mainframeChatter(let density, let seekRate):
            let voice = VintageMainframeVoice(density: density, seekRate: seekRate)
            return voice
        }
    }

    private func startUpdateTimer() {
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let t = Float(Date().timeIntervalSince(self.startTime))
            self.elapsedTime = t
            for layer in self.activeLayers {
                layer.update(time: t)
            }
        }
    }
}
