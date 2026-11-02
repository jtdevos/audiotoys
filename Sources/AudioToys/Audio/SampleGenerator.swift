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

        // Calm School Classroom Samples
        let chalkUrl = dir.appendingPathComponent("chalk_writing.wav")
        if !FileManager.default.fileExists(atPath: chalkUrl.path) {
            createChalkWritingWav(url: chalkUrl)
        }

        let coughUrl = dir.appendingPathComponent("classroom_cough.wav")
        if !FileManager.default.fileExists(atPath: coughUrl.path) {
            createClassroomCoughWav(url: coughUrl)
        }

        // Coffee Shop Samples
        let glassesUrl = dir.appendingPathComponent("cafe_glasses_clink.wav")
        if !FileManager.default.fileExists(atPath: glassesUrl.path) {
            createCafeGlassesClinkWav(url: glassesUrl)
        }

        let registerUrl = dir.appendingPathComponent("cafe_cash_register.wav")
        if !FileManager.default.fileExists(atPath: registerUrl.path) {
            createCafeCashRegisterWav(url: registerUrl)
        }

        let espressoUrl = dir.appendingPathComponent("cafe_espresso_steam.wav")
        if !FileManager.default.fileExists(atPath: espressoUrl.path) {
            createCafeEspressoSteamWav(url: espressoUrl)
        }

        let murmurUrl = dir.appendingPathComponent("cafe_murmur.wav")
        if !FileManager.default.fileExists(atPath: murmurUrl.path) {
            createCafeMurmurWav(url: murmurUrl)
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

    // MARK: - Calm School Classroom Foley Generation

    /// Soft calcium-carbonate chalk strokes and light taps on a slate blackboard
    private static func createChalkWritingWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 4.2
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        struct ChalkStroke {
            let start: Double
            let length: Double
            let pressure: Float
            let centerFreq: Float
        }

        let strokes: [ChalkStroke] = [
            ChalkStroke(start: 0.12, length: 0.28, pressure: 0.55, centerFreq: 2450),
            ChalkStroke(start: 0.55, length: 0.38, pressure: 0.65, centerFreq: 2280),
            ChalkStroke(start: 1.15, length: 0.22, pressure: 0.48, centerFreq: 2620),
            ChalkStroke(start: 1.52, length: 0.44, pressure: 0.62, centerFreq: 2180),
            ChalkStroke(start: 2.25, length: 0.18, pressure: 0.45, centerFreq: 2750), // quick dot/cross
            ChalkStroke(start: 2.68, length: 0.48, pressure: 0.60, centerFreq: 2340),
            ChalkStroke(start: 3.42, length: 0.34, pressure: 0.52, centerFreq: 2510)
        ]

        var bpZ1: Float = 0, bpZ2: Float = 0
        var lpState: Float = 0

        for stroke in strokes {
            let startIdx = Int(stroke.start * sampleRate)
            let lenFrames = Int(stroke.length * sampleRate)
            guard startIdx + lenFrames < frameCount else { continue }

            let f = 2.0 * sin(Float.pi * stroke.centerFreq / Float(sampleRate))
            let q: Float = 0.55

            for k in 0..<lenFrames {
                let localT = Double(k) / sampleRate
                let progress = localT / stroke.length

                // Initial chalk-tip contact tap on slate (first 10ms)
                var tap: Float = 0
                if localT < 0.012 {
                    let tapEnv = Float(exp(-localT * 320.0))
                    tap = (sin(Float(localT * 1950.0 * 2.0 * .pi)) * 0.55 +
                           sin(Float(localT * 520.0 * 2.0 * .pi)) * 0.45) * tapEnv * 0.42
                }

                // Smooth cursive hand velocity envelope with micro-grain slate texture
                let strokeEnv = Float(sin(progress * .pi))
                let grainMod = Float(0.70 + 0.30 * sin(localT * 68.0 * 2.0 * .pi) * cos(localT * 113.0 * 2.0 * .pi))

                let white = Float.random(in: -1.0...1.0)
                let hp = white - bpZ2 - q * bpZ1
                bpZ1 += f * hp
                bpZ2 += f * bpZ1

                // Slate board warm low-mid resonance (480 Hz)
                lpState = 0.90 * lpState + 0.10 * white
                let friction = (bpZ1 * 0.65 + lpState * 0.35) * strokeEnv * grainMod * stroke.pressure

                samples[startIdx + k] += (tap + friction * 0.38)
            }
        }

        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }

    /// Soft, polite muffled cough / throat-clear across a quiet room
    private static func createClassroomCoughWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 2.6
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        // Two-part muffled cough burst (0.35s and 0.62s)
        let pulses: [(start: Double, len: Double, amp: Float, f1: Double, f2: Double)] = [
            (0.35, 0.19, 0.52, 460.0, 1080.0),
            (0.60, 0.15, 0.34, 420.0, 980.0)
        ]

        var lp1: Float = 0
        var lp2: Float = 0

        for p in pulses {
            let startIdx = Int(p.start * sampleRate)
            let lenFrames = Int(p.len * sampleRate)
            guard startIdx + lenFrames < frameCount else { continue }

            for k in 0..<lenFrames {
                let t = Double(k) / sampleRate
                // Fast glottal opening (18ms) followed by exponentially damped exhalation
                let env: Float = t < 0.018
                    ? Float(t / 0.018)
                    : Float(exp(-(t - 0.018) * 16.5))

                let white = Float.random(in: -1.0...1.0)
                // Vocal tract chest & pharynx formants + low-frequency glottal rumble (115 Hz)
                let glottal = sin(Float(t * 115.0 * 2.0 * .pi)) * 0.35 + sin(Float(t * 230.0 * 2.0 * .pi)) * 0.20
                let formantCarrier = sin(Float(t * p.f1 * 2.0 * .pi)) * 0.5 + sin(Float(t * p.f2 * 2.0 * .pi)) * 0.3
                let raw = (white * 0.65 + formantCarrier * white * 0.55 + glottal * 0.45) * env * p.amp

                // Sleeve/room muffling low-pass filter
                lp1 += 0.14 * (raw - lp1)
                lp2 += 0.14 * (lp1 - lp2)
                samples[startIdx + k] += lp2 * 0.55
            }
        }

        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }

    // MARK: - Coffee Shop Ambiance & Foley Generation

    /// Porcelain saucers, glassware clinks, and silver spoons stirring in ceramic mugs
    private static func createCafeGlassesClinkWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 4.4
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        struct ClinkEvent {
            let time: Double
            let f1: Double
            let f2: Double
            let f3: Double
            let decay: Double
            let amp: Float
        }

        let events: [ClinkEvent] = [
            // Ceramic cup set on saucer (warm porcelain ring + wood table thud)
            ClinkEvent(time: 0.18, f1: 1420, f2: 2890, f3: 4350, decay: 18.0, amp: 0.52),
            ClinkEvent(time: 0.23, f1: 310,  f2: 820,  f3: 1420, decay: 32.0, amp: 0.35),
            // Silver spoon stirring clinks against mug rim
            ClinkEvent(time: 1.05, f1: 2340, f2: 4120, f3: 6480, decay: 24.0, amp: 0.44),
            ClinkEvent(time: 1.38, f1: 2410, f2: 4210, f3: 6620, decay: 26.0, amp: 0.38),
            ClinkEvent(time: 1.72, f1: 2360, f2: 4150, f3: 6510, decay: 22.0, amp: 0.40),
            // Clear drinking glass tinkle
            ClinkEvent(time: 2.65, f1: 1880, f2: 3640, f3: 5820, decay: 11.5, amp: 0.55),
            ClinkEvent(time: 3.45, f1: 2120, f2: 3980, f3: 6150, decay: 14.0, amp: 0.46)
        ]

        for ev in events {
            let startIdx = Int(ev.time * sampleRate)
            let ringFrames = Int(0.55 * sampleRate)
            guard startIdx + ringFrames < frameCount else { continue }

            for k in 0..<ringFrames {
                let t = Double(k) / sampleRate
                let env1 = Float(exp(-t * ev.decay))
                let env2 = Float(exp(-t * ev.decay * 1.45))
                let env3 = Float(exp(-t * ev.decay * 2.10))

                // Subtle doublet beating for authentic cylindrical glass/porcelain wall modes
                let m1 = sin(Float(t * ev.f1 * 2.0 * .pi)) + 0.45 * sin(Float(t * (ev.f1 + 3.2) * 2.0 * .pi))
                let m2 = sin(Float(t * ev.f2 * 2.0 * .pi))
                let m3 = sin(Float(t * ev.f3 * 2.0 * .pi))
                let impactTransient = t < 0.003 ? Float.random(in: -0.4...0.4) * Float(exp(-t * 900.0)) : 0

                let val = (m1 * env1 * 0.55 + m2 * env2 * 0.30 + m3 * env3 * 0.15 + impactTransient) * ev.amp * 0.55
                samples[startIdx + k] += val
            }
        }

        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }

    /// Mechanical counter register button taps, drawer slide, and warm brass bell chime
    private static func createCafeCashRegisterWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 3.2
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        // 1. Three tactile key clicks (0.12s, 0.28s, 0.44s)
        let keyTimes = [0.12, 0.28, 0.44]
        for kt in keyTimes {
            let startIdx = Int(kt * sampleRate)
            let clickFrames = Int(0.035 * sampleRate)
            for k in 0..<clickFrames where startIdx + k < frameCount {
                let t = Double(k) / sampleRate
                let env = Float(exp(-t * 140.0))
                let click = (sin(Float(t * 1450.0 * 2.0 * .pi)) * 0.5 + sin(Float(t * 280.0 * 2.0 * .pi)) * 0.5) * env
                samples[startIdx + k] += click * 0.42
            }
        }

        // 2. Spring-loaded drawer latch & roller slide at 0.68s
        let slideStart = Int(0.68 * sampleRate)
        let slideFrames = Int(0.26 * sampleRate)
        var slideLP: Float = 0
        for k in 0..<slideFrames where slideStart + k < frameCount {
            let t = Double(k) / sampleRate
            let env = Float(sin((t / 0.26) * .pi))
            let white = Float.random(in: -1.0...1.0)
            slideLP = 0.82 * slideLP + 0.18 * white
            let roller = sin(Float(t * 165.0 * 2.0 * .pi)) * 0.35 + slideLP * 0.45
            samples[slideStart + k] += roller * env * 0.38
        }

        // 3. Classic brass register bell chime at 0.74s
        let bellStart = Int(0.74 * sampleRate)
        let bellFrames = Int(1.8 * sampleRate)
        for k in 0..<bellFrames where bellStart + k < frameCount {
            let t = Double(k) / sampleRate
            let env1 = Float(exp(-t * 3.8))
            let env2 = Float(exp(-t * 6.5))
            let env3 = Float(exp(-t * 11.0))
            // Bronze/brass bell partials (G6 fundamental 1568 Hz + inharmonic overtones)
            let p1 = sin(Float(t * 1568.0 * 2.0 * .pi)) * env1
            let p2 = sin(Float(t * 3142.0 * 2.0 * .pi)) * env2 * 0.48
            let p3 = sin(Float(t * 4685.0 * 2.0 * .pi)) * env3 * 0.22
            samples[bellStart + k] += (p1 + p2 + p3) * 0.42
        }

        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }

    /// Barista portafilter knock followed by warm milk-steaming microfoam wand aeration
    private static func createCafeEspressoSteamWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 3.8
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        // Two muted wooden knock-box taps at 0.15s and 0.38s
        for knockTime in [0.15, 0.38] {
            let startIdx = Int(knockTime * sampleRate)
            let len = Int(0.06 * sampleRate)
            for k in 0..<len where startIdx + k < frameCount {
                let t = Double(k) / sampleRate
                let env = Float(exp(-t * 85.0))
                let wood = (sin(Float(t * 195.0 * 2.0 * .pi)) * 0.65 + sin(Float(t * 410.0 * 2.0 * .pi)) * 0.35) * env
                samples[startIdx + k] += wood * 0.48
            }
        }

        // Steam wand milk texturing from 0.75s to 3.45s
        let steamStart = Int(0.75 * sampleRate)
        let steamLen = Int(2.70 * sampleRate)
        var z1: Float = 0, z2: Float = 0
        for k in 0..<steamLen where steamStart + k < frameCount {
            let t = Double(k) / sampleRate
            let env: Float
            if t < 0.12 {
                env = Float(t / 0.12)
            } else if t > 2.35 {
                env = Float(max(0.0, (2.70 - t) / 0.35))
            } else {
                env = 1.0
            }

            // Center frequency drops slightly from 1450 Hz to 1020 Hz as milk heats & thickens
            let progress = Float(t / 2.70)
            let fc = 1450.0 - 430.0 * progress
            let f = 2.0 * sin(Float.pi * fc / Float(sampleRate))
            let q: Float = 0.65

            let white = Float.random(in: -1.0...1.0)
            let hp = white - z2 - q * z1
            z1 += f * hp
            z2 += f * z1

            // Microfoam eddies (26 Hz & 43 Hz gentle liquid modulation)
            let bubbleMod = Float(0.80 + 0.20 * sin(t * 26.0 * 2.0 * .pi) * cos(t * 43.0 * 2.0 * .pi))
            samples[steamStart + k] += (z1 * 0.65 + z2 * 0.35) * env * bubbleMod * 0.38
        }

        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }

    /// Warm, unintelligible multi-table conversational murmur for a cozy neighborhood coffee shop
    private static func createCafeMurmurWav(url: URL) {
        let sampleRate: Double = 44100
        let duration: Double = 6.0
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        // Simulate 5 distinct distant conversationalists with syllabic envelopes & vowel formants
        struct VoiceModel {
            let pitchHz: Double
            let syllableRate: Double
            let phaseOffset: Double
            let f1Base: Float
            let f2Base: Float
            var z1: Float = 0
            var z2: Float = 0
        }

        var voices: [VoiceModel] = [
            VoiceModel(pitchHz: 118, syllableRate: 3.8, phaseOffset: 0.0, f1Base: 440, f2Base: 1150),
            VoiceModel(pitchHz: 195, syllableRate: 4.4, phaseOffset: 1.3, f1Base: 560, f2Base: 1580),
            VoiceModel(pitchHz: 142, syllableRate: 3.3, phaseOffset: 2.7, f1Base: 480, f2Base: 1320),
            VoiceModel(pitchHz: 215, syllableRate: 4.9, phaseOffset: 4.1, f1Base: 610, f2Base: 1720),
            VoiceModel(pitchHz: 105, syllableRate: 3.6, phaseOffset: 5.2, f1Base: 390, f2Base: 1020)
        ]

        var roomLP: Float = 0

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var mix: Float = 0

            for vIdx in 0..<voices.count {
                var v = voices[vIdx]
                // Syllabic cadence with conversational pauses
                let sylWave = sin(t * v.syllableRate * 2.0 * .pi + v.phaseOffset)
                let phraseWave = sin(t * (v.syllableRate * 0.22) * 2.0 * .pi + v.phaseOffset * 1.7)
                let sylEnv = Float(max(0.0, sylWave) * max(0.15, 0.55 + 0.45 * phraseWave))

                // Soft glottal + breath source
                let vibrato = 1.0 + 0.025 * sin(t * 5.2 * 2.0 * .pi + v.phaseOffset)
                let f0 = v.pitchHz * vibrato
                let glottal = Float(sin(t * f0 * 2.0 * .pi) * 0.45 +
                                    sin(t * f0 * 2.0 * 2.0 * .pi) * 0.30 +
                                    sin(t * f0 * 3.0 * 2.0 * .pi) * 0.15)
                let breath = Float.random(in: -1.0...1.0) * 0.35
                let excitation = (glottal + breath) * sylEnv

                // Moving vowel formant bandpass filter
                let formantSweep = v.f1Base + 160.0 * Float(sin(t * 2.1 * 2.0 * .pi + v.phaseOffset))
                let f = 2.0 * sin(Float.pi * formantSweep / Float(sampleRate))
                let q: Float = 0.42
                let hp = excitation - v.z2 - q * v.z1
                v.z1 += f * hp
                v.z2 += f * v.z1
                voices[vIdx] = v

                mix += v.z1 * 0.22
            }

            // Warm cafe room absorption low-pass filter (keeps murmur soothing and unintelligible)
            roomLP = 0.78 * roomLP + 0.22 * mix
            samples[i] = roomLP * 0.65
        }

        writeWavFile(url: url, sampleRate: sampleRate, channels: 1, samples: samples)
    }
}
