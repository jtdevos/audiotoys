import Foundation
import AVFoundation

public enum ReverbEnvironmentPreset: String, CaseIterable, Identifiable {
    case cathedral = "Cathedral"
    case largeChamber = "Large Chamber"
    case mediumRoom = "Medium Room"
    case plate = "Plate Reverb"
    case smallRoom = "Small Room"
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
/// real-time HRTF 3D spatialization, and active audio layers.
public final class SpatialAudioEngine: ObservableObject, @unchecked Sendable {
    public let engine = AVAudioEngine()
    public let environmentNode = AVAudioEnvironmentNode()

    @Published public private(set) var isRunning: Bool = false
    @Published public var masterVolume: Float = 0.85 {
        didSet {
            engine.mainMixerNode.outputVolume = masterVolume
        }
    }
    @Published public var currentReverb: ReverbEnvironmentPreset = .largeChamber {
        didSet {
            applyReverb(currentReverb)
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
        let envFormat = AVAudioFormat(standardFormatWithSampleRate: outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 44100.0,
                                      channels: 2)!

        engine.connect(environmentNode, to: engine.mainMixerNode, format: envFormat)

        // Apple High-Quality HRTF binaural spatial rendering for AirPods Pro & headphones
        environmentNode.renderingAlgorithm = .HRTFHQ
        environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        environmentNode.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: 0, pitch: 0, roll: 0)

        // Distance attenuation
        environmentNode.distanceAttenuationParameters.distanceAttenuationModel = .exponential
        environmentNode.distanceAttenuationParameters.referenceDistance = 1.0
        environmentNode.distanceAttenuationParameters.maximumDistance = 25.0
        environmentNode.distanceAttenuationParameters.rolloffFactor = 1.0

        applyReverb(currentReverb)
        engine.mainMixerNode.outputVolume = masterVolume
    }

    public func applyReverb(_ preset: ReverbEnvironmentPreset) {
        if let avPre = preset.avPreset {
            environmentNode.reverbParameters.enable = true
            environmentNode.reverbParameters.loadFactoryReverbPreset(avPre)
            environmentNode.reverbParameters.level = -14.0
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
            print("🔊 SpatialAudioEngine started with HRTFHQ 3D audio rendering.")
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

        switch layer.source {
        case .procedural(let config):
            let voice = createDSPVoice(for: config)
            layer.dspVoice = voice
            let sampleRate = standardFormat.sampleRate

            let sourceNode = AVAudioSourceNode(format: standardFormat) { [weak layer] _, _, frameCount, audioBufferList -> OSStatus in
                let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
                guard let buffer = abl[0].mData?.assumingMemoryBound(to: Float.self) else {
                    return noErr
                }
                memset(buffer, 0, Int(frameCount) * MemoryLayout<Float>.size)
                guard let l = layer, !l.isMuted, l.volume > 0.0001 else { return noErr }
                voice.render(buffer: buffer, frameCount: Int(frameCount), sampleRate: sampleRate)
                let vol = l.volume
                if vol < 0.999 {
                    for i in 0..<Int(frameCount) {
                        buffer[i] *= vol
                    }
                }
                return noErr
            }

            engine.attach(sourceNode)
            engine.connect(sourceNode, to: environmentNode, format: standardFormat)
            layer.audioNode = sourceNode

            // Configure 3D mixing
            sourceNode.renderingAlgorithm = .HRTFHQ
            sourceNode.reverbBlend = 0.28
            let initialPos = layer.currentPosition
            sourceNode.position = AVAudio3DPoint(x: initialPos.x, y: initialPos.y, z: initialPos.z)

        case .audioFile(let path, let isLooping, _):
            let fileURL: URL
            if path.starts(with: "/") {
                fileURL = URL(fileURLWithPath: path)
            } else {
                fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent(path)
            }

            guard let audioFile = try? AVAudioFile(forReading: fileURL) else {
                print("⚠️ Could not load audio file at: \(fileURL.path)")
                return
            }
            layer.audioFile = audioFile

            let playerNode = AVAudioPlayerNode()
            engine.attach(playerNode)
            engine.connect(playerNode, to: environmentNode, format: audioFile.processingFormat)
            layer.playerNode = playerNode
            layer.audioNode = playerNode

            playerNode.renderingAlgorithm = .HRTFHQ
            playerNode.reverbBlend = 0.22
            let initialPos = layer.currentPosition
            playerNode.position = AVAudio3DPoint(x: initialPos.x, y: initialPos.y, z: initialPos.z)
            playerNode.volume = layer.volume

            if isLooping {
                playerNode.scheduleFile(audioFile, at: nil) { [weak playerNode, weak audioFile] in
                    // Reschedule loop on completion
                    guard let p = playerNode, let f = audioFile else { return }
                    p.scheduleFile(f, at: nil)
                }
                if isEngineRunning {
                    playerNode.play()
                }
            } else {
                layer.triggerAudioFile()
            }
        }

        layer.environmentNode = environmentNode
        activeLayers.append(layer)

        if isEngineRunning && !engine.isRunning {
            try? engine.start()
        }
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
        // 60 fps motion updates
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
