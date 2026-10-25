import Foundation
import AVFoundation

public enum ProceduralVoiceConfig: Codable, Equatable {
    case fmBell(baseFreq: Float, modRatio: Double, interval: Double)
    case pluckedString(baseFreq: Float, interval: Double)
    case filteredNoise(type: String, cutoff: Float, resonance: Float)
    case granularImpulse(type: String, density: Float)
    case subtractiveDrone(fundamental: Float, detune: Float)
    case mainframeChatter(density: Float, seekRate: Float)
}

public enum LayerSource: Codable, Equatable {
    case procedural(ProceduralVoiceConfig)
    case audioFile(path: String, isLooping: Bool, interval: Double)
}

/// Represents an audio layer in 3D space with its synthesis/playback engine,
/// 5-stage acoustic filter chain, and 3D spatial motion script.
public final class AudioLayer: Identifiable, ObservableObject, @unchecked Sendable {
    public let id: String
    public var name: String
    public var colorHex: String
    public var source: LayerSource
    public var motionScript: MotionScript
    public let filterChain: AcousticFilterChain

    @Published public var volume: Float = 1.0 {
        didSet { updateVolume() }
    }
    @Published public var isMuted: Bool = false {
        didSet { updateVolume() }
    }
    @Published public var isSolo: Bool = false

    @Published public var currentPosition: Vector3 = .zero
    @Published public var recentTrail: [Vector3] = []
    @Published public var activityLevel: Float = 0.0
    @Published public var proximityPercent: Int = 0

    // CoreAudio node references
    public var environmentNode: AVAudioEnvironmentNode?
    public var audioNode: AVAudioNode?
    public var playerNode: AVAudioPlayerNode?
    public var audioFile: AVAudioFile?
    public var dspVoice: DSPVoice?

    private var maxTrailPoints: Int = 28

    public init(id: String = UUID().uuidString,
                name: String,
                colorHex: String = "#00FFAA",
                source: LayerSource,
                motionScript: MotionScript,
                volume: Float = 1.0,
                acousticProfile: AcousticProfile? = nil) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.source = source
        self.motionScript = motionScript
        self.volume = volume
        let initialPos = motionScript.position(at: 0)
        self.currentPosition = initialPos

        let resolvedProfile = acousticProfile ?? AudioLayer.inferProfile(name: name, source: source)
        self.filterChain = AcousticFilterChain(profile: resolvedProfile)
        self.filterChain.updateSpatialPosition(initialPos)
        self.proximityPercent = Int((self.filterChain.proximityFactor * 100.0).rounded())
    }

    /// Automatically chooses the optimal acoustic filter chain profile from the layer's name & source.
    public static func inferProfile(name: String, source: LayerSource) -> AcousticProfile {
        let lower = name.lowercased()
        if lower.contains("shear") || lower.contains("scissor") || lower.contains("snip") {
            return .crispShears
        }
        if lower.contains("clipper") || lower.contains("trimmer") || lower.contains("shaver") || lower.contains("purr") {
            return .warmMotor
        }
        if lower.contains("brush") || lower.contains("comb") || lower.contains("duster") || lower.contains("page") || lower.contains("pencil") {
            return .velvetBrush
        }
        if lower.contains("spray") || lower.contains("mist") || lower.contains("scalp") || lower.contains("shampoo") || lower.contains("towel") || lower.contains("whisper") {
            return .intimateASMR
        }
        if lower.contains("wood") || lower.contains("clock") || lower.contains("watch") || lower.contains("hearth") || lower.contains("fire") || lower.contains("ember") {
            return .resonantWood
        }
        if lower.contains("rumble") || lower.contains("thunder") || lower.contains("reactor") || lower.contains("warp") || lower.contains("cosmic") {
            return .deepSub
        }
        if lower.contains("bowl") || lower.contains("chime") || lower.contains("harp") || lower.contains("music box") {
            return .crystalline
        }
        return .naturalFoley
    }

    public func update(time: Float) {
        let pos = motionScript.position(at: time)
        self.currentPosition = pos

        // Update 5-stage acoustic filter chain with 3D distance and front/back pinna cues
        filterChain.updateSpatialPosition(pos)
        proximityPercent = Int((filterChain.proximityFactor * 100.0).rounded())

        // Update 3D position and dynamic distance-based reverb blend in CoreAudio environment
        if let mixingNode = audioNode as? AVAudio3DMixing {
            mixingNode.position = AVAudio3DPoint(x: pos.x, y: pos.y, z: pos.z)
            // Near-field sounds (<0.5m) are ultra-direct & dry (0.03) for intimate ASMR presence;
            // far-field sounds blend naturally into the room reverb (up to 0.34).
            let dist = pos.magnitude
            let dynamicReverb = max(0.02, min(0.35, (dist - 0.18) * 0.14))
            mixingNode.reverbBlend = dynamicReverb
        }

        // Add to breadcrumb trail
        recentTrail.append(pos)
        if recentTrail.count > maxTrailPoints {
            recentTrail.removeFirst()
        }

        // Smoothly track actual real-time acoustic RMS & Peak telemetry from the filter chain
        let targetActivity = isMuted ? 0.0 : min(1.0, filterChain.lastRMS * 6.5 + filterChain.lastPeak * 0.45)
        activityLevel = activityLevel * 0.72 + targetActivity * 0.28
    }

    public func updateVolume() {
        let effectiveVol: Float = isMuted ? 0.0 : volume
        playerNode?.volume = effectiveVol
    }

    public func triggerAudioFile() {
        dspVoice?.triggerNote(pitchHz: 440.0, velocity: 0.9)
        activityLevel = 0.85
    }
}
