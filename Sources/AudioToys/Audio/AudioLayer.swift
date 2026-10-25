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

/// Represents an audio layer in 3D space with its synthesis/playback engine and motion script.
public final class AudioLayer: Identifiable, ObservableObject, @unchecked Sendable {
    public let id: String
    public var name: String
    public var colorHex: String
    public var source: LayerSource
    public var motionScript: MotionScript

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

    // CoreAudio node references
    public var environmentNode: AVAudioEnvironmentNode?
    public var audioNode: AVAudioNode?
    public var playerNode: AVAudioPlayerNode?
    public var audioFile: AVAudioFile?
    public var dspVoice: DSPVoice?

    private var maxTrailPoints: Int = 24
    private var lastTriggerTime: Double = 0

    public init(id: String = UUID().uuidString,
                name: String,
                colorHex: String = "#00FFAA",
                source: LayerSource,
                motionScript: MotionScript,
                volume: Float = 1.0) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.source = source
        self.motionScript = motionScript
        self.volume = volume
        self.currentPosition = motionScript.position(at: 0)
    }

    public func update(time: Float) {
        let pos = motionScript.position(at: time)
        self.currentPosition = pos

        // Update 3D position in CoreAudio environment
        if let audioNode = audioNode as? AVAudio3DMixing {
            audioNode.position = AVAudio3DPoint(x: pos.x, y: pos.y, z: pos.z)
        }

        // Add to breadcrumb trail
        recentTrail.append(pos)
        if recentTrail.count > maxTrailPoints {
            recentTrail.removeFirst()
        }

        // Decay visual activity level
        activityLevel = max(0, activityLevel - 0.04)

        // If audio file layer is not continuous loop but periodic trigger
        if case .audioFile(_, let isLooping, let interval) = source, !isLooping && interval > 0 {
            if Double(time) - lastTriggerTime >= interval {
                lastTriggerTime = Double(time)
                triggerAudioFile()
            }
        }
    }

    public func updateVolume() {
        let effectiveVol: Float = isMuted ? 0.0 : volume
        playerNode?.volume = effectiveVol
    }

    public func triggerAudioFile() {
        guard let player = playerNode, let file = audioFile else { return }
        player.scheduleFile(file, at: nil) { [weak self] in
            DispatchQueue.main.async {
                self?.activityLevel = 0.0
            }
        }
        if !player.isPlaying {
            player.play()
        }
        activityLevel = 1.0
    }
}
