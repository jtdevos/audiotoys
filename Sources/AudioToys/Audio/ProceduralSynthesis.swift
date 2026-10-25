import Foundation
import AVFoundation

/// DSP Voice protocol that renders raw audio samples on the real-time audio thread.
public protocol DSPVoice: AnyObject, Sendable {
    func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double)
    func triggerNote(pitchHz: Float, velocity: Float)
}

// MARK: - Musical Scales & Frequencies

public struct MusicalScale {
    public static let minorPentatonic: [Float] = [0, 3, 5, 7, 10]
    public static let majorPentatonic: [Float] = [0, 2, 4, 7, 9]
    public static let dorian: [Float] = [0, 2, 3, 5, 7, 9, 10]
    public static let akebono: [Float] = [0, 2, 3, 7, 8] // Japanese mystical scale
    public static let celestial: [Float] = [0, 4, 7, 11, 14, 18] // Major 9/11 ambient

    public static func noteToHz(baseHz: Float, semiTones: Float) -> Float {
        baseHz * pow(2.0, semiTones / 12.0)
    }
}

// MARK: - 1. FM Bell / Crystalline Chime Voice

public final class FMBellVoice: DSPVoice, @unchecked Sendable {
    private var phaseCarrier: Double = 0
    private var phaseModulator: Double = 0
    private var carrierFreq: Double = 440.0
    private var modFreqRatio: Double = 2.756 // Inharmonic ratio for bell/bowl
    private var modIndex: Double = 2.5
    private var currentModIndex: Double = 2.5
    private var envelope: Double = 0.0
    private var decayRate: Double = 0.99992 // Smooth long ring

    // Automatic generative triggers
    public var autoTriggerInterval: Double = 3.0
    public var lastTriggerTime: Double = 0
    public var baseFreq: Float = 330.0 // E4
    public var scale: [Float] = MusicalScale.minorPentatonic
    private var timeAccumulator: Double = 0

    public init(baseFreq: Float = 330.0, modRatio: Double = 2.756, modIndex: Double = 2.5) {
        self.baseFreq = baseFreq
        self.carrierFreq = Double(baseFreq)
        self.modFreqRatio = modRatio
        self.modIndex = modIndex
    }

    public func triggerNote(pitchHz: Float, velocity: Float = 0.8) {
        self.carrierFreq = Double(pitchHz)
        self.envelope = Double(velocity)
        self.currentModIndex = self.modIndex * Double(velocity)
    }

    public func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let twoPi = 2.0 * Double.pi
        let samplePeriod = 1.0 / sampleRate
        let modFreq = carrierFreq * modFreqRatio

        for i in 0..<frameCount {
            timeAccumulator += samplePeriod

            // Check auto trigger
            if autoTriggerInterval > 0 && (timeAccumulator - lastTriggerTime) >= autoTriggerInterval {
                lastTriggerTime = timeAccumulator
                let octave = Int.random(in: 0...2)
                let noteIndex = Int.random(in: 0..<scale.count)
                let semitones = scale[noteIndex] + Float(octave * 12)
                let hz = MusicalScale.noteToHz(baseHz: baseFreq, semiTones: semitones)
                triggerNote(pitchHz: hz, velocity: Float.random(in: 0.5...0.85))
                // Slight variation in next interval for organic pacing
                autoTriggerInterval = Double.random(in: 2.5...5.5)
            }

            if envelope > 0.0001 {
                phaseModulator += modFreq * twoPi / sampleRate
                if phaseModulator > twoPi { phaseModulator -= twoPi }

                let modSample = sin(phaseModulator) * currentModIndex
                phaseCarrier += (carrierFreq + modSample * carrierFreq) * twoPi / sampleRate
                if phaseCarrier > twoPi { phaseCarrier -= twoPi }

                let sample = sin(phaseCarrier) * envelope
                buffer[i] += Float(sample)

                envelope *= decayRate
                currentModIndex *= decayRate
            }
        }
    }
}

// MARK: - 2. Karplus-Strong Plucked String Voice

public final class PluckedStringVoice: DSPVoice, @unchecked Sendable {
    private var delayLine: [Float]
    private var readIndex: Int = 0
    private var writeIndex: Int = 0
    private var delayLength: Int = 400
    private var feedback: Float = 0.992
    private var filterState: Float = 0.0

    public var autoTriggerInterval: Double = 2.0
    public var lastTriggerTime: Double = 0
    public var baseFreq: Float = 220.0 // A3
    public var scale: [Float] = MusicalScale.celestial
    private var timeAccumulator: Double = 0

    public init(maxDelay: Int = 2048) {
        self.delayLine = Array(repeating: 0.0, count: maxDelay)
    }

    public func triggerNote(pitchHz: Float, velocity: Float = 0.8) {
        let period = Int(44100.0 / max(50.0, min(2000.0, pitchHz)))
        self.delayLength = min(period, delayLine.count - 1)
        self.readIndex = 0
        self.writeIndex = delayLength

        // Fill delay buffer with noise burst
        for i in 0..<delayLength {
            let noise = (Float.random(in: -1.0...1.0)) * velocity
            delayLine[i] = noise
        }
        filterState = 0.0
    }

    public func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let samplePeriod = 1.0 / sampleRate

        for i in 0..<frameCount {
            timeAccumulator += samplePeriod

            if autoTriggerInterval > 0 && (timeAccumulator - lastTriggerTime) >= autoTriggerInterval {
                lastTriggerTime = timeAccumulator
                let octave = Int.random(in: 0...2)
                let noteIndex = Int.random(in: 0..<scale.count)
                let semitones = scale[noteIndex] + Float(octave * 12)
                let hz = MusicalScale.noteToHz(baseHz: baseFreq, semiTones: semitones)
                triggerNote(pitchHz: hz, velocity: Float.random(in: 0.4...0.75))
                autoTriggerInterval = Double.random(in: 1.5...4.0)
            }

            guard delayLength > 0 else { continue }

            let outSample = delayLine[readIndex]

            // Two-point averaging lowpass filter in feedback loop
            let nextSample = delayLine[(readIndex + 1) % delayLength]
            let filtered = (outSample + nextSample) * 0.5 * feedback

            delayLine[readIndex] = filtered

            readIndex = (readIndex + 1) % delayLength

            buffer[i] += outSample * 0.4
        }
    }
}

// MARK: - 3. Filtered Noise Voice (Wind, Breeze, Ocean Surf)

public final class FilteredNoiseVoice: DSPVoice, @unchecked Sendable {
    public enum NoiseType { case pink, brown, white }

    public var noiseType: NoiseType = .pink
    public var baseCutoff: Float = 800.0
    public var resonance: Float = 2.5
    public var lfoSpeed: Float = 0.15 // Gentle breathing cycle
    public var lfoDepth: Float = 400.0

    // Filter states (Biquad resonant filter)
    private var b0: Float = 0, b1: Float = 0, b2: Float = 0, a1: Float = 0, a2: Float = 0
    private var x1: Float = 0, x2: Float = 0, y1: Float = 0, y2: Float = 0

    // Pink noise state
    private var b_pink: (Float, Float, Float, Float, Float, Float, Float) = (0,0,0,0,0,0,0)
    // Brown noise state
    private var brownState: Float = 0.0

    private var lfoPhase: Float = 0.0

    public init(type: NoiseType = .pink, cutoff: Float = 600.0, resonance: Float = 2.0) {
        self.noiseType = type
        self.baseCutoff = cutoff
        self.resonance = resonance
    }

    public func triggerNote(pitchHz: Float, velocity: Float) {
        self.baseCutoff = pitchHz
    }

    public func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let sr = Float(sampleRate)

        for i in 0..<frameCount {
            // LFO for organic wind whoosh
            lfoPhase += lfoSpeed * 2.0 * Float.pi / sr
            if lfoPhase > Float.pi * 2.0 { lfoPhase -= Float.pi * 2.0 }
            let cutoff = max(100.0, min(8000.0, baseCutoff + sin(lfoPhase) * lfoDepth))

            // Update biquad bandpass coefficients
            let omega = 2.0 * Float.pi * cutoff / sr
            let alpha = sin(omega) / (2.0 * resonance)
            let cosW = cos(omega)
            let a0 = 1.0 + alpha
            b0 = alpha / a0
            b1 = 0.0
            b2 = -alpha / a0
            a1 = (-2.0 * cosW) / a0
            a2 = (1.0 - alpha) / a0

            // Generate noise
            let white = Float.random(in: -1.0...1.0)
            let rawNoise: Float
            switch noiseType {
            case .white:
                rawNoise = white
            case .pink:
                b_pink.0 = 0.99886 * b_pink.0 + white * 0.0555179
                b_pink.1 = 0.99332 * b_pink.1 + white * 0.0750759
                b_pink.2 = 0.96900 * b_pink.2 + white * 0.1538520
                b_pink.3 = 0.86650 * b_pink.3 + white * 0.3104856
                b_pink.4 = 0.55000 * b_pink.4 + white * 0.5329522
                b_pink.5 = -0.7616 * b_pink.5 - white * 0.0168980
                rawNoise = (b_pink.0 + b_pink.1 + b_pink.2 + b_pink.3 + b_pink.4 + b_pink.5 + white * 0.5362) * 0.11
            case .brown:
                brownState = (brownState + (0.02 * white)) / 1.02
                rawNoise = brownState * 3.5
            }

            // Biquad filtering
            let outSample = b0 * rawNoise + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            x2 = x1
            x1 = rawNoise
            y2 = y1
            y1 = outSample

            buffer[i] += outSample * 0.35
        }
    }
}

// MARK: - 4. Granular Impulses (Raindrops & Fire Crackles)

public final class GranularImpulseVoice: DSPVoice, @unchecked Sendable {
    public enum ImpulseType { case raindrop, campfire, clockTick }

    public var type: ImpulseType = .raindrop
    public var density: Float = 15.0 // impulses per second

    private struct ActivePuff {
        var freq: Float
        var phase: Float
        var amplitude: Float
        var decay: Float
    }
    private var activePuffs: [ActivePuff] = []

    public init(type: ImpulseType = .raindrop, density: Float = 18.0) {
        self.type = type
        self.density = density
    }

    public func triggerNote(pitchHz: Float, velocity: Float) {
        spawnImpulse(freq: pitchHz, velocity: velocity)
    }

    private func spawnImpulse(freq: Float? = nil, velocity: Float? = nil) {
        switch type {
        case .raindrop:
            let f = freq ?? Float.random(in: 1200...3500)
            let v = velocity ?? Float.random(in: 0.15...0.4)
            activePuffs.append(ActivePuff(freq: f, phase: 0, amplitude: v, decay: Float.random(in: 0.991...0.996)))
        case .campfire:
            let f = freq ?? Float.random(in: 300...1800)
            let v = velocity ?? Float.random(in: 0.2...0.6)
            activePuffs.append(ActivePuff(freq: f, phase: 0, amplitude: v, decay: Float.random(in: 0.985...0.993)))
        case .clockTick:
            let f = freq ?? 1800.0
            let v = velocity ?? 0.5
            activePuffs.append(ActivePuff(freq: f, phase: 0, amplitude: v, decay: 0.988))
        }
    }

    public func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let sr = Float(sampleRate)
        let prob = density / sr

        for i in 0..<frameCount {
            // Stochastic Poisson trigger
            if Float.random(in: 0.0...1.0) < prob {
                spawnImpulse()
            }

            var sum: Float = 0
            var writeIdx = 0
            for idx in 0..<activePuffs.count {
                var puff = activePuffs[idx]
                puff.phase += puff.freq * 2.0 * Float.pi / sr
                let s = sin(puff.phase) * puff.amplitude
                puff.amplitude *= puff.decay
                sum += s

                if puff.amplitude > 0.001 {
                    activePuffs[writeIdx] = puff
                    writeIdx += 1
                }
            }
            if writeIdx < activePuffs.count {
                activePuffs.removeSubrange(writeIdx..<activePuffs.count)
            }

            buffer[i] += sum * 0.4
        }
    }
}

// MARK: - 5. Subtractive Multi-Oscillator Drone Voice

public final class SubtractiveDroneVoice: DSPVoice, @unchecked Sendable {
    public var fundamentalFreq: Float = 110.0 // A2
    public var detuneCents: Float = 8.0
    public var filterCutoff: Float = 450.0
    public var lfoRate: Float = 0.08

    private var phase1: Float = 0
    private var phase2: Float = 0
    private var phase3: Float = 0
    private var lfoPhase: Float = 0
    private var filterState: Float = 0

    public init(fundamental: Float = 110.0) {
        self.fundamentalFreq = fundamental
    }

    public func triggerNote(pitchHz: Float, velocity: Float) {
        self.fundamentalFreq = pitchHz
    }

    public func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let sr = Float(sampleRate)
        let f1 = fundamentalFreq
        let f2 = fundamentalFreq * pow(2.0, detuneCents / 1200.0)
        let f3 = fundamentalFreq * pow(2.0, -detuneCents / 1200.0)

        for i in 0..<frameCount {
            lfoPhase += lfoRate * 2.0 * Float.pi / sr
            let cutoff = filterCutoff * (1.0 + 0.3 * sin(lfoPhase))
            let rc = 1.0 / (2.0 * Float.pi * cutoff)
            let dt = 1.0 / sr
            let alpha = dt / (rc + dt)

            phase1 += f1 * 2.0 * Float.pi / sr
            phase2 += f2 * 2.0 * Float.pi / sr
            phase3 += f3 * 2.0 * Float.pi / sr
            if phase1 > Float.pi * 2.0 { phase1 -= Float.pi * 2.0 }
            if phase2 > Float.pi * 2.0 { phase2 -= Float.pi * 2.0 }
            if phase3 > Float.pi * 2.0 { phase3 -= Float.pi * 2.0 }

            // Warm triangle & sine blend
            let s1 = (2.0 / Float.pi) * asin(sin(phase1))
            let s2 = (2.0 / Float.pi) * asin(sin(phase2))
            let s3 = sin(phase3)

            let mix = (s1 + s2 + s3) * 0.333

            filterState += alpha * (mix - filterState)

            buffer[i] += filterState * 0.4
        }
    }
}

// MARK: - 6. Vintage Mainframe & Chunky Hard Drive Voice (MU-TH-UR 6000)

public final class VintageMainframeVoice: DSPVoice, @unchecked Sendable {
    public var density: Float = 14.0 // Seek clatter events per second
    public var seekRate: Float = 4.0 // Seek clusters per second
    public var spindleHumFreq: Float = 120.0

    private struct ActiveClick {
        var freq: Float
        var thudFreq: Float
        var phase: Float
        var thudPhase: Float
        var amplitude: Float
        var decay: Float
    }
    private var activeClicks: [ActiveClick] = []
    private var spindlePhase: Float = 0
    private var timeAccumulator: Double = 0
    private var lastBurstTime: Double = 0
    private var inBurst: Bool = false
    private var burstRemainingClicks: Int = 0
    private var nextClickTime: Double = 0

    public init(density: Float = 14.0, seekRate: Float = 4.0) {
        self.density = density
        self.seekRate = seekRate
    }

    public func triggerNote(pitchHz: Float, velocity: Float) {
        spawnClick(freq: pitchHz, velocity: velocity)
    }

    private func spawnClick(freq: Float? = nil, velocity: Float? = nil) {
        let f = freq ?? Float.random(in: 1400...3200)
        let thudF = Float.random(in: 120...240)
        let v = velocity ?? Float.random(in: 0.3...0.7)
        let dec = Float.random(in: 0.982...0.992)
        activeClicks.append(ActiveClick(freq: f, thudFreq: thudF, phase: 0, thudPhase: 0, amplitude: v, decay: dec))
    }

    public func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let sr = Float(sampleRate)
        let dt = 1.0 / sampleRate

        for i in 0..<frameCount {
            timeAccumulator += dt

            // Spindle motor bearing hum (120Hz + 240Hz harmonics)
            spindlePhase += spindleHumFreq * 2.0 * Float.pi / sr
            if spindlePhase > Float.pi * 2.0 { spindlePhase -= Float.pi * 2.0 }
            let hum = (sin(spindlePhase) * 0.05 + sin(spindlePhase * 2.0) * 0.03)

            // Trigger burst of head seeks (Winchester drive accessing cylinders)
            if !inBurst && (timeAccumulator - lastBurstTime) >= Double(1.0 / max(0.5, seekRate)) {
                lastBurstTime = timeAccumulator
                inBurst = true
                burstRemainingClicks = Int.random(in: 3...8)
                nextClickTime = timeAccumulator
            }

            if inBurst && timeAccumulator >= nextClickTime {
                spawnClick(velocity: Float.random(in: 0.4...0.85))
                burstRemainingClicks -= 1
                if burstRemainingClicks <= 0 {
                    inBurst = false
                } else {
                    nextClickTime = timeAccumulator + Double.random(in: 0.025...0.065)
                }
            }

            // Occasional background relay click
            if Float.random(in: 0...1) < (density * 0.3 / sr) {
                spawnClick(freq: Float.random(in: 800...1600), velocity: Float.random(in: 0.2...0.45))
            }

            // Render active mechanical clicks
            var sum: Float = 0
            var writeIdx = 0
            for idx in 0..<activeClicks.count {
                var c = activeClicks[idx]
                c.phase += c.freq * 2.0 * Float.pi / sr
                c.thudPhase += c.thudFreq * 2.0 * Float.pi / sr
                let clickSound = (sin(c.phase) * 0.6 + sin(c.thudPhase) * 0.4) * c.amplitude
                c.amplitude *= c.decay
                sum += clickSound

                if c.amplitude > 0.001 {
                    activeClicks[writeIdx] = c
                    writeIdx += 1
                }
            }
            if writeIdx < activeClicks.count {
                activeClicks.removeSubrange(writeIdx..<activeClicks.count)
            }

            buffer[i] += (sum * 0.5 + hum) * 0.65
        }
    }
}

