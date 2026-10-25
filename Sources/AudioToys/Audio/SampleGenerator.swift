import Foundation
import AVFoundation

/// Generates built-in reference WAV sample files so that audio file playback
/// works out of the box with zero external dependencies.
public struct SampleGenerator {
    public static func generateDefaultSamples(inDirectory dir: URL) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let thunderUrl = dir.appendingPathComponent("distant_thunder.wav")
        if !FileManager.default.fileExists(atPath: thunderUrl.path) {
            createThunderWav(url: thunderUrl)
        }

        let cricketUrl = dir.appendingPathComponent("cricket_chirp.wav")
        if !FileManager.default.fileExists(atPath: cricketUrl.path) {
            createCricketWav(url: cricketUrl)
        }

        let clockUrl = dir.appendingPathComponent("clock_tick.wav")
        if !FileManager.default.fileExists(atPath: clockUrl.path) {
            createClockTickWav(url: clockUrl)
        }

        let bowlUrl = dir.appendingPathComponent("singing_bowl.wav")
        if !FileManager.default.fileExists(atPath: bowlUrl.path) {
            createSingingBowlWav(url: bowlUrl)
        }

        // Nostromo & MU-TH-UR 6000 Samples
        let nostromoSeekUrl = dir.appendingPathComponent("nostromo_drive_seek.wav")
        if !FileManager.default.fileExists(atPath: nostromoSeekUrl.path) {
            createNostromoDriveSeekWav(url: nostromoSeekUrl)
        }

        let nostromoSpinupUrl = dir.appendingPathComponent("nostromo_drive_spinup.wav")
        if !FileManager.default.fileExists(atPath: nostromoSpinupUrl.path) {
            createNostromoDriveSpinupWav(url: nostromoSpinupUrl)
        }

        let nostromoBeepsUrl = dir.appendingPathComponent("nostromo_muthur_beeps.wav")
        if !FileManager.default.fileExists(atPath: nostromoBeepsUrl.path) {
            createNostromoMuthurBeepsWav(url: nostromoBeepsUrl)
        }

        let nostromoHullUrl = dir.appendingPathComponent("nostromo_hull_rumble.wav")
        if !FileManager.default.fileExists(atPath: nostromoHullUrl.path) {
            createNostromoHullRumbleWav(url: nostromoHullUrl)
        }

        let nostromoVentUrl = dir.appendingPathComponent("nostromo_coolant_vent.wav")
        if !FileManager.default.fileExists(atPath: nostromoVentUrl.path) {
            createNostromoCoolantVentWav(url: nostromoVentUrl)
        }
    }

    private static func writeWavFile(url: URL, sampleRate: Double, channels: Int, samples: [Float]) {
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        guard let audioFile = try? AVAudioFile(forWriting: url, settings: settings) else {
            return
        }

        let format = audioFile.processingFormat
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else {
            return
        }
        pcmBuffer.frameLength = AVAudioFrameCount(samples.count)

        if let channelData = pcmBuffer.floatChannelData?[0] {
            for i in 0..<samples.count {
                channelData[i] = max(-1.0, min(1.0, samples[i]))
            }
        }

        try? audioFile.write(from: pcmBuffer)
    }

    // MARK: - Standard Reference Sounds

    private static func createThunderWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 4.0
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        var brown: Float = 0
        var lp: Float = 0
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let white = Float.random(in: -1.0...1.0)
            brown = (brown + 0.03 * white) / 1.03
            let sub = sin(Float(t * 45.0 * 2.0 * .pi)) * 0.4 + sin(Float(t * 72.0 * 2.0 * .pi)) * 0.25
            let env = t < 0.6 ? Float(t / 0.6) : Float(exp(-(t - 0.6) * 0.9))
            let raw = (brown * 2.0 + sub) * env
            lp = lp + 0.05 * (raw - lp)
            samples[i] = lp * 0.7
        }
        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }

    private static func createCricketWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 2.0
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let chirpPhase = fmod(t * 3.5, 1.0)
            let inChirp = chirpPhase < 0.4
            if inChirp {
                let subPulse = sin(chirpPhase * 45.0 * 2.0 * .pi)
                let carrier = sin(t * 4600.0 * 2.0 * .pi) + 0.3 * sin(t * 9200.0 * 2.0 * .pi)
                let env = sin(chirpPhase / 0.4 * .pi)
                samples[i] = Float(carrier * subPulse * env * 0.5)
            }
        }
        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }

    private static func createClockTickWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 1.0
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            if t < 0.08 {
                let env = Float(exp(-t * 80.0))
                let click = sin(Float(t * 1850.0 * 2.0 * .pi)) * env
                let thud = sin(Float(t * 320.0 * 2.0 * .pi)) * Float(exp(-t * 40.0))
                samples[i] = (click * 0.7 + thud * 0.3) * 0.6
            }
        }
        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }

    private static func createSingingBowlWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 5.0
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let env1 = Float(exp(-t * 0.4))
            let env2 = Float(exp(-t * 0.8))
            let env3 = Float(exp(-t * 1.5))
            let f1 = sin(Float(t * 261.6 * 2.0 * .pi)) * env1
            let f2 = sin(Float(t * 543.2 * 2.0 * .pi)) * env2 * 0.6
            let f3 = sin(Float(t * 892.4 * 2.0 * .pi)) * env3 * 0.3
            samples[i] = (f1 + f2 + f3) * 0.5
        }
        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }

    // MARK: - Nostromo & MU-TH-UR 6000 Cinematic Sound Generation

    /// Chunky 1970s Winchester/MFM Hard Drive head seek clatter with teletype relay chatter
    private static func createNostromoDriveSeekWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 3.6
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        // Multiple seek bursts characteristic of MU-TH-UR processing disk sectors
        struct SeekEvent {
            let time: Double
            let freq: Float
            let intensity: Float
        }
        var events: [SeekEvent] = []

        // Generate rapid clusters of head seeks
        let clusters = [0.1, 0.45, 0.85, 1.4, 1.9, 2.35, 2.9, 3.2]
        for clusterStart in clusters {
            let burstCount = Int.random(in: 4...9)
            var curTime = clusterStart
            for _ in 0..<burstCount {
                let f = Float.random(in: 1400...2800)
                let inten = Float.random(in: 0.5...0.95)
                events.append(SeekEvent(time: curTime, freq: f, intensity: inten))
                curTime += Double.random(in: 0.02...0.055)
            }
        }

        // Render each seek event
        for ev in events {
            let startIdx = Int(ev.time * sampleRate)
            let burstFrames = Int(0.04 * sampleRate)
            guard startIdx + burstFrames < frameCount else { continue }

            for f in 0..<burstFrames {
                let t = Double(f) / sampleRate
                // Sharp mechanical impact: high metal click + low chassis thud
                let clickEnv = Float(exp(-t * 240.0))
                let thudEnv = Float(exp(-t * 65.0))
                let click = sin(Float(t * Double(ev.freq) * 2.0 * .pi)) * clickEnv
                let thud = sin(Float(t * 180.0 * 2.0 * .pi)) * thudEnv
                let noiseSnap = Float.random(in: -1...1) * Float(exp(-t * 400.0))

                let sampleVal = (click * 0.55 + thud * 0.4 + noiseSnap * 0.25) * ev.intensity
                samples[startIdx + f] += sampleVal * 0.45
            }
        }

        // Add subtle constant spindle bearing hum in the background
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let bearing = sin(Float(t * 120.0 * 2.0 * .pi)) * 0.04 + sin(Float(t * 240.0 * 2.0 * .pi)) * 0.025
            let airHiss = Float.random(in: -0.01...0.01)
            samples[i] += bearing + airHiss
        }

        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }

    /// Heavy disk platter and tape spindle spinning up from zero RPM to operating speed
    private static func createNostromoDriveSpinupWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 5.5
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        var filterState: Float = 0

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate

            // Motor acceleration curve from 0 to target RPM (240 Hz hum)
            let rpmProgress: Double
            if t < 3.2 {
                let frac = t / 3.2
                rpmProgress = frac * frac // ease-in spinup
            } else {
                rpmProgress = 1.0 // steady-state
            }

            let motorFreq = 35.0 + rpmProgress * 205.0 // 35Hz -> 240Hz
            let motorPhase = t * motorFreq * 2.0 * .pi
            let motorHarmonicPhase = t * (motorFreq * 2.0) * 2.0 * .pi

            let motorTone = sin(Float(motorPhase)) * 0.35 + sin(Float(motorHarmonicPhase)) * 0.18

            // Platter aerodynamic air drag and bearing whine
            let airNoise = Float.random(in: -1.0...1.0) * Float(0.08 + rpmProgress * 0.18)
            filterState = filterState + 0.15 * (airNoise - filterState)

            // Subtle tape reel flutter / tension arm clicking
            let flutter = sin(Float(t * 7.5 * 2.0 * .pi)) * 0.06
            let tensionTick: Float
            let tickPhase = fmod(t * (2.0 + rpmProgress * 6.0), 1.0)
            if tickPhase < 0.03 {
                tensionTick = Float.random(in: 0.1...0.25)
            } else {
                tensionTick = 0
            }

            let mix = (motorTone + filterState + tensionTick + flutter) * Float(0.5 + rpmProgress * 0.5)
            samples[i] = mix * 0.65
        }

        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }

    /// Iconic MU-TH-UR 6000 dual-tone electronic data query chirps
    private static func createNostromoMuthurBeepsWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 2.4
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        // Staccato dual-tone pairs characteristic of 1970s mainframe query responses
        struct ToneBurst {
            let start: Double
            let length: Double
            let f1: Double
            let f2: Double
        }

        let tones: [ToneBurst] = [
            ToneBurst(start: 0.10, length: 0.065, f1: 1760.0, f2: 2640.0),
            ToneBurst(start: 0.22, length: 0.055, f1: 1320.0, f2: 1980.0),
            ToneBurst(start: 0.34, length: 0.075, f1: 2200.0, f2: 3300.0),
            ToneBurst(start: 0.48, length: 0.050, f1: 1568.0, f2: 2352.0),
            ToneBurst(start: 0.60, length: 0.090, f1: 1174.0, f2: 1760.0),
            ToneBurst(start: 0.85, length: 0.120, f1: 2093.0, f2: 3136.0), // Affirmation beep
            ToneBurst(start: 1.30, length: 0.050, f1: 1480.0, f2: 2220.0),
            ToneBurst(start: 1.42, length: 0.065, f1: 1975.0, f2: 2960.0),
            ToneBurst(start: 1.58, length: 0.110, f1: 2637.0, f2: 3951.0)
        ]

        for tb in tones {
            let startIdx = Int(tb.start * sampleRate)
            let lengthFrames = Int(tb.length * sampleRate)
            guard startIdx + lengthFrames < frameCount else { continue }

            for f in 0..<lengthFrames {
                let t = Double(f) / sampleRate
                // Quick rounded envelope to avoid harsh square click
                let env: Float
                let attackTime = 0.005
                let decayTime = 0.015
                if t < attackTime {
                    env = Float(t / attackTime)
                } else if t > tb.length - decayTime {
                    env = Float((tb.length - t) / decayTime)
                } else {
                    env = 1.0
                }

                // Dual sine blend with subtle harmonic warmth
                let s1 = sin(Float(t * tb.f1 * 2.0 * .pi)) * 0.6
                let s2 = sin(Float(t * tb.f2 * 2.0 * .pi)) * 0.4
                samples[startIdx + f] += (s1 + s2) * env * 0.45
            }
        }

        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }

    /// Massive industrial sub-bass hull rumble from the Nostromo's nuclear fusion engines
    private static func createNostromoHullRumbleWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 6.0
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        var brown: Float = 0
        var lp: Float = 0

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate

            // Multi-harmonic sub-bass engine frequencies: 38Hz, 44Hz (beating), 76Hz, 114Hz
            let osc1 = sin(Float(t * 38.0 * 2.0 * .pi)) * 0.45
            let osc2 = sin(Float(t * 41.5 * 2.0 * .pi)) * 0.35 // 3.5Hz beating vibration
            let osc3 = sin(Float(t * 76.0 * 2.0 * .pi)) * 0.22
            let osc4 = sin(Float(t * 114.0 * 2.0 * .pi)) * 0.12

            // Low frequency turbulent rumbling
            let white = Float.random(in: -1.0...1.0)
            brown = (brown + 0.02 * white) / 1.02
            lp = lp + 0.035 * (brown - lp)

            // Slow industrial respiration cycle (20 second wave)
            let swell = Float(0.85 + 0.15 * sin(t * 0.35 * 2.0 * .pi))

            let raw = (osc1 + osc2 + osc3 + osc4 + lp * 1.8) * swell
            samples[i] = raw * 0.55
        }

        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }

    /// Overhead environmental life support pressurized coolant venting
    private static func createNostromoCoolantVentWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 3.5
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        var b0: Float = 0, b1: Float = 0, b2: Float = 0
        var x1: Float = 0, x2: Float = 0, y1: Float = 0, y2: Float = 0

        // Resonant bandpass filter coefficients for steam / gas hiss
        let cutoff: Float = 2400.0
        let omega = 2.0 * Float.pi * cutoff / Float(sampleRate)
        let alpha = sin(omega) / (2.0 * 1.8)
        let a0 = 1.0 + alpha
        b0 = alpha / a0
        b1 = 0
        b2 = -alpha / a0
        let a1 = (-2.0 * cos(omega)) / a0
        let a2 = (1.0 - alpha) / a0

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate

            // Solenoid valve burst: rapid open over 0.08s, hiss sustain for 0.8s, slow pressure decay
            let env: Float
            if t < 0.08 {
                env = Float(t / 0.08)
            } else if t < 1.0 {
                env = 1.0 - Float((t - 0.08) * 0.2)
            } else {
                env = Float(exp(-(t - 1.0) * 1.6)) * 0.8
            }

            let white = Float.random(in: -1.0...1.0)
            let filtered = b0 * white + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            x2 = x1
            x1 = white
            y2 = y1
            y1 = filtered

            // Valve click at start
            let valveClick = t < 0.02 ? sin(Float(t * 850.0 * 2.0 * .pi)) * Float(exp(-t * 200.0)) * 0.6 : 0

            samples[i] = (filtered * env * 0.6 + valveClick) * 0.5
        }

        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }
}
