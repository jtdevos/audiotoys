import Foundation
import AVFoundation

/// DSP Voice protocol that renders raw audio samples on the real-time audio thread.
public protocol DSPVoice: AnyObject, Sendable {
    func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double)
    func triggerNote(pitchHz: Float, velocity: Float)
}

// MARK: - Musical Scales & Tuning

public struct MusicalScale {
    public static let minorPentatonic: [Float] = [0, 3, 5, 7, 10]
    public static let majorPentatonic: [Float] = [0, 2, 4, 7, 9]
    public static let dorian: [Float] = [0, 2, 3, 5, 7, 9, 10]
    public static let akebono: [Float] = [0, 2, 3, 7, 8]
    public static let celestial: [Float] = [0, 4, 7, 11, 14, 19]

    public static func noteToHz(baseHz: Float, semiTones: Float) -> Float {
        baseHz * pow(2.0, semiTones / 12.0)
    }
}

// MARK: - 1. 8-Mode Inharmonic Singing Bowl & Chime Modal Resonator

/// Replaces basic 2-op sine FM with an 8-mode physical modal resonator bank
/// featuring natural acoustic beating doublets and a felt-wrapped wooden mallet strike exciter.
public final class FMBellVoice: DSPVoice, @unchecked Sendable {
    private struct ModalPartial {
        var freq: Double
        var phase: Double
        var amp: Double
        var decay: Double
        var weight: Double
    }

    private var partials: [ModalPartial] = []
    private var malletNoiseEnv: Double = 0.0
    private var malletLPF: Double = 0.0

    public var autoTriggerInterval: Double = 3.5
    public var lastTriggerTime: Double = 0
    public var baseFreq: Float = 261.6
    public var modFreqRatio: Double = 2.756
    public var scale: [Float] = MusicalScale.akebono
    private var timeAccumulator: Double = 0

    public init(baseFreq: Float = 261.6, modRatio: Double = 2.756, modIndex: Double = 2.5) {
        self.baseFreq = baseFreq
        self.modFreqRatio = modRatio
        setupPartials(fundamental: Double(baseFreq), sampleRate: 44100.0)
    }

    private func setupPartials(fundamental f0: Double, sampleRate sr: Double) {
        // Authentic Tibetan bronze bowl / Koshi chime overtone ratios with subtle doublet beating (0.9Hz - 2.3Hz)
        let ratios: [(ratio: Double, beatHz: Double, weight: Double, t60: Double)] = [
            (1.000, 0.00, 1.00, 7.5),
            (1.000, 1.15, 0.75, 7.2), // Warm fundamental beating pair
            (modFreqRatio, 0.00, 0.62, 4.8),
            (modFreqRatio, 1.85, 0.45, 4.5), // Second mode shimmer doublet
            (5.404, 0.00, 0.28, 2.4),
            (5.404, 2.60, 0.18, 2.1),
            (8.933, 0.00, 0.11, 1.1),
            (13.34, 0.00, 0.05, 0.55)
        ]

        partials.removeAll(keepingCapacity: true)
        for r in ratios {
            let freq = min(sr * 0.44, f0 * r.ratio + r.beatHz)
            // Decay per sample for target T60 reverberation time
            let decay = exp(-6.9078 / (r.t60 * sr))
            partials.append(ModalPartial(
                freq: freq,
                phase: Double.random(in: 0...(2.0 * .pi)),
                amp: 0.0,
                decay: decay,
                weight: r.weight
            ))
        }
    }

    public func triggerNote(pitchHz: Float, velocity: Float = 0.75) {
        setupPartials(fundamental: Double(pitchHz), sampleRate: 44100.0)
        let vel = Double(velocity)
        for i in 0..<partials.count {
            partials[i].amp = vel * partials[i].weight
        }
        malletNoiseEnv = vel * 0.35
    }

    public func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let twoPi = 2.0 * Double.pi
        let dt = 1.0 / sampleRate

        for i in 0..<frameCount {
            timeAccumulator += dt

            if autoTriggerInterval > 0 && (timeAccumulator - lastTriggerTime) >= autoTriggerInterval {
                lastTriggerTime = timeAccumulator
                let octave = Int.random(in: 0...1)
                let noteIndex = Int.random(in: 0..<scale.count)
                let semitones = scale[noteIndex] + Float(octave * 12)
                let hz = MusicalScale.noteToHz(baseHz: baseFreq, semiTones: semitones)
                triggerNote(pitchHz: hz, velocity: Float.random(in: 0.45...0.78))
                autoTriggerInterval = Double.random(in: 3.2...6.8)
            }

            var sampleSum: Double = 0.0

            // Soft felt/wood mallet impact transient
            if malletNoiseEnv > 0.0002 {
                let white = Double.random(in: -1.0...1.0)
                malletLPF += 0.08 * (white - malletLPF)
                sampleSum += malletLPF * malletNoiseEnv
                malletNoiseEnv *= 0.994
            }

            for pIdx in 0..<partials.count {
                var p = partials[pIdx]
                if p.amp > 0.00008 {
                    p.phase += p.freq * twoPi * dt
                    if p.phase > twoPi { p.phase -= twoPi }
                    sampleSum += sin(p.phase) * p.amp
                    p.amp *= p.decay
                    partials[pIdx] = p
                }
            }

            buffer[i] += Float(sampleSum * 0.28)
        }
    }
}

// MARK: - 2. Acoustic Waveguide Plucked Harp & Koto with Cedar Body Resonator

public final class PluckedStringVoice: DSPVoice, @unchecked Sendable {
    private var delayLine: [Float]
    private var readIndex: Int = 0
    private var delayLength: Int = 400
    private var feedback: Float = 0.9945
    private var lpState: Float = 0.0
    private var dcPrevX: Float = 0.0
    private var dcPrevY: Float = 0.0

    // Cedar soundboard body resonator (195 Hz & 420 Hz acoustic box modes)
    private var bodyZ1_A: Float = 0.0, bodyZ2_A: Float = 0.0
    private var bodyZ1_B: Float = 0.0, bodyZ2_B: Float = 0.0

    public var autoTriggerInterval: Double = 2.4
    public var lastTriggerTime: Double = 0
    public var baseFreq: Float = 220.0
    public var scale: [Float] = MusicalScale.celestial
    private var timeAccumulator: Double = 0

    public init(maxDelay: Int = 4096) {
        self.delayLine = Array(repeating: 0.0, count: maxDelay)
    }

    public func triggerNote(pitchHz: Float, velocity: Float = 0.75) {
        let clampedHz = max(55.0, min(1600.0, pitchHz))
        let period = Int(44100.0 / clampedHz)
        self.delayLength = min(period, delayLine.count - 1)
        self.readIndex = 0
        self.feedback = min(0.9965, 0.991 + (1.0 - clampedHz / 1800.0) * 0.005)

        // Warm finger-flesh pluck excitation: pink-filtered noise + pick-position comb filter
        let pickOffset = max(2, Int(Float(delayLength) * Float.random(in: 0.18...0.32)))
        var rawBuf = [Float](repeating: 0.0, count: delayLength)
        var pinkLP: Float = 0.0
        for i in 0..<delayLength {
            let w = Float.random(in: -1.0...1.0)
            pinkLP = 0.68 * pinkLP + 0.32 * w
            let window = sin(Float(i) / Float(delayLength) * Float.pi)
            rawBuf[i] = pinkLP * window * velocity
        }
        for i in 0..<delayLength {
            let combIdx = (i + pickOffset) % delayLength
            delayLine[i] = rawBuf[i] - 0.65 * rawBuf[combIdx]
        }
        lpState = 0.0
    }

    public func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let dt = 1.0 / sampleRate
        let sr = Float(sampleRate)

        // Soundboard body resonator coefficients (220 Hz warm wood mode)
        let wBody = 2.0 * Float.pi * 220.0 / sr
        let rBody: Float = 0.965
        let a1Body = -2.0 * rBody * cos(wBody)
        let a2Body = rBody * rBody

        for i in 0..<frameCount {
            timeAccumulator += dt

            if autoTriggerInterval > 0 && (timeAccumulator - lastTriggerTime) >= autoTriggerInterval {
                lastTriggerTime = timeAccumulator
                let octave = Int.random(in: 0...1)
                let noteIndex = Int.random(in: 0..<scale.count)
                let semitones = scale[noteIndex] + Float(octave * 12)
                let hz = MusicalScale.noteToHz(baseHz: baseFreq, semiTones: semitones)
                triggerNote(pitchHz: hz, velocity: Float.random(in: 0.45...0.78))
                autoTriggerInterval = Double.random(in: 1.8...4.2)
            }

            guard delayLength > 2 else { continue }

            let outSample = delayLine[readIndex]
            let nextSample = delayLine[(readIndex + 1) % delayLength]

            // Warm bridge damping low-pass filter in waveguide loop
            let avg = 0.65 * outSample + 0.35 * nextSample
            lpState = 0.25 * lpState + 0.75 * avg
            delayLine[readIndex] = lpState * feedback

            readIndex = (readIndex + 1) % delayLength

            // DC blocker
            let dcOut = outSample - dcPrevX + 0.995 * dcPrevY
            dcPrevX = outSample
            dcPrevY = dcOut

            // Couple string to wooden soundboard resonator
            let bodyOut = dcOut * 0.035 - a1Body * bodyZ1_A - a2Body * bodyZ2_A
            bodyZ2_A = bodyZ1_A
            bodyZ1_A = bodyOut

            buffer[i] += (dcOut * 0.32 + bodyOut * 0.25)
        }
    }
}

// MARK: - 3. Natural Multi-Formant Wind, Breeze & Foliage Voice

public final class FilteredNoiseVoice: DSPVoice, @unchecked Sendable {
    public enum NoiseType { case pink, brown, white }

    public var noiseType: NoiseType = .pink
    public var baseCutoff: Float = 520.0
    public var resonance: Float = 1.6

    private var b_pink: (Float, Float, Float, Float, Float, Float) = (0, 0, 0, 0, 0, 0)
    private var brownState: Float = 0.0

    // Dual formant filters for natural outdoor wind & foliage rustle
    private var f1_z1: Float = 0, f1_z2: Float = 0
    private var f2_z1: Float = 0, f2_z2: Float = 0
    private var lfoPhase1: Float = Float.random(in: 0...6.28)
    private var lfoPhase2: Float = Float.random(in: 0...6.28)

    public init(type: NoiseType = .pink, cutoff: Float = 520.0, resonance: Float = 1.6) {
        self.noiseType = type
        self.baseCutoff = cutoff
        self.resonance = max(0.7, min(3.5, resonance))
    }

    public func triggerNote(pitchHz: Float, velocity: Float) {
        self.baseCutoff = pitchHz
    }

    public func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let sr = Float(sampleRate)

        for i in 0..<frameCount {
            // Slow organic double-sine wind swell (0.09 Hz and 0.23 Hz)
            lfoPhase1 += 0.09 * 2.0 * Float.pi / sr
            lfoPhase2 += 0.23 * 2.0 * Float.pi / sr
            if lfoPhase1 > Float.pi * 2.0 { lfoPhase1 -= Float.pi * 2.0 }
            if lfoPhase2 > Float.pi * 2.0 { lfoPhase2 -= Float.pi * 2.0 }

            let gust = 0.55 + 0.30 * sin(lfoPhase1) + 0.15 * sin(lfoPhase2)
            let cutoff1 = max(110.0, min(4200.0, baseCutoff * (0.65 + 0.55 * gust)))

            let white = Float.random(in: -1.0...1.0)
            let rawNoise: Float
            switch noiseType {
            case .white:
                // Soften pure white noise into silky air hiss
                b_pink.0 = 0.85 * b_pink.0 + 0.15 * white
                rawNoise = b_pink.0 * 0.5
            case .pink:
                b_pink.0 = 0.99886 * b_pink.0 + white * 0.0555179
                b_pink.1 = 0.99332 * b_pink.1 + white * 0.0750759
                b_pink.2 = 0.96900 * b_pink.2 + white * 0.1538520
                b_pink.3 = 0.86650 * b_pink.3 + white * 0.3104856
                b_pink.4 = 0.55000 * b_pink.4 + white * 0.5329522
                b_pink.5 = -0.7616 * b_pink.5 - white * 0.0168980
                rawNoise = (b_pink.0 + b_pink.1 + b_pink.2 + b_pink.3 + b_pink.4 + b_pink.5 + white * 0.5362) * 0.09
            case .brown:
                brownState = (brownState + 0.018 * white) / 1.018
                rawNoise = brownState * 2.8
            }

            // State-variable 2-pole low-pass + bandpass blend (no harsh whistling)
            let f = 2.0 * sin(Float.pi * cutoff1 / sr)
            let q = 1.0 / max(0.8, resonance * 0.75)
            let hp = rawNoise - f1_z2 - q * f1_z1
            f1_z1 += f * hp
            f1_z2 += f * f1_z1

            let out = (f1_z2 * 0.72 + f1_z1 * 0.28) * gust
            buffer[i] += out * 0.30
        }
    }
}

// MARK: - 4. Velvet-Noise & Physical Micro-Foley Impulse Engine
// (Raindrops on Glass, Hearth Embers, Mechanical Escapement, Japanese Barber Shears & Comb)

public final class GranularImpulseVoice: DSPVoice, @unchecked Sendable {
    public enum ImpulseType {
        case raindrop
        case campfire
        case clockTick
        case barberScissors
        case barberComb
    }

    public var type: ImpulseType = .raindrop
    public var density: Float = 16.0

    private struct AcousticGrain {
        var modeFreq1: Float
        var modeFreq2: Float
        var chirpRate: Float
        var phase1: Float = 0
        var phase2: Float = 0
        var toneAmp: Float
        var toneDecay: Float
        var noiseAmp: Float
        var noiseDecay: Float
        var noiseFilter: Float = 0
    }

    private var grains: [AcousticGrain] = []
    private var velvetBedState: Float = 0.0
    private var tickToggle: Bool = false
    private var timeAccumulator: Double = 0.0
    private var nextEventTime: Double = 0.0
    private var snipBurstRemaining: Int = 0

    public init(type: ImpulseType = .raindrop, density: Float = 16.0) {
        self.type = type
        self.density = density
    }

    public func triggerNote(pitchHz: Float, velocity: Float) {
        spawnPhysicalGrain(velocity: velocity)
    }

    private func spawnPhysicalGrain(velocity: Float? = nil) {
        guard grains.count < 24 else { return }

        switch type {
        case .raindrop:
            // Real water drop hitting skylight glass:
            // 1) Broadband water impact transient (2ms)
            // 2) Damped skylight glass plate mode (340..620 Hz)
            // 3) Tiny Minnaert air bubble cavity chirp (1400..2800 Hz upward pitch slide)
            let v = velocity ?? Float.random(in: 0.14...0.42)
            grains.append(AcousticGrain(
                modeFreq1: Float.random(in: 320...580),
                modeFreq2: Float.random(in: 1350...2700),
                chirpRate: Float.random(in: 1.0003...1.0008),
                toneAmp: v * 0.35,
                toneDecay: Float.random(in: 0.992...0.9955),
                noiseAmp: v * 0.85,
                noiseDecay: Float.random(in: 0.965...0.982)
            ))

        case .campfire:
            // Real wood-fire ember pop & resin crackle:
            // Sharp lignin snap (0.8ms) + low hearth cavity resonance (140..260 Hz)
            let v = velocity ?? Float.random(in: 0.18...0.55)
            grains.append(AcousticGrain(
                modeFreq1: Float.random(in: 135...255),
                modeFreq2: Float.random(in: 2200...4800),
                chirpRate: 0.9998,
                toneAmp: v * 0.30,
                toneDecay: Float.random(in: 0.986...0.992),
                noiseAmp: v * 1.10,
                noiseDecay: Float.random(in: 0.945...0.975)
            ))

        case .clockTick:
            // Authentic anchor escapement: alternating 'Tick' (pallet lock) and 'Tock' (pallet unlock)
            tickToggle.toggle()
            let v = velocity ?? Float.random(in: 0.38...0.48)
            let f1: Float = tickToggle ? 245.0 : 210.0 // Mahogany clock case resonance
            let f2: Float = tickToggle ? 2680.0 : 2240.0 // Brass escape wheel tooth ring
            grains.append(AcousticGrain(
                modeFreq1: f1,
                modeFreq2: f2,
                chirpRate: 1.0,
                toneAmp: v * 0.42,
                toneDecay: 0.989,
                noiseAmp: v * 0.90,
                noiseDecay: 0.940
            ))

        case .barberScissors:
            // Japanese convex steel barber shears closing:
            // High-frequency dispersive steel blade modes (4.8kHz & 8.9kHz) gliding upward in pitch
            // as the contact point moves from pivot to tip, plus thumb-ring stop thud (260Hz)
            let v = velocity ?? Float.random(in: 0.35...0.65)
            grains.append(AcousticGrain(
                modeFreq1: Float.random(in: 4400...5600),
                modeFreq2: Float.random(in: 8200...10800),
                chirpRate: 1.00045,
                toneAmp: v * 0.38,
                toneDecay: Float.random(in: 0.9935...0.9960),
                noiseAmp: v * 0.95,
                noiseDecay: Float.random(in: 0.985...0.991)
            ))
            // Add brass handle thumb-ring stop thud
            grains.append(AcousticGrain(
                modeFreq1: Float.random(in: 220...290),
                modeFreq2: Float.random(in: 1650...2100),
                chirpRate: 0.9995,
                toneAmp: v * 0.28,
                toneDecay: 0.988,
                noiseAmp: v * 0.30,
                noiseDecay: 0.960
            ))

        case .barberComb:
            // Single comb tooth micro-pluck (called in rapid cascades)
            let v = velocity ?? Float.random(in: 0.15...0.35)
            grains.append(AcousticGrain(
                modeFreq1: Float.random(in: 1100...3600),
                modeFreq2: Float.random(in: 4800...7800),
                chirpRate: 1.0002,
                toneAmp: v * 0.25,
                toneDecay: 0.986,
                noiseAmp: v * 0.75,
                noiseDecay: 0.965
            ))
        }
    }

    public func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let sr = Float(sampleRate)
        let dt = 1.0 / sampleRate
        let twoPi = 2.0 * Float.pi

        for i in 0..<frameCount {
            timeAccumulator += dt

            switch type {
            case .clockTick:
                // Exact rhythmic escapement cadence (density = ticks per second, e.g. 2.0 or 4.0 Hz)
                let period = 1.0 / Double(max(0.5, density))
                if timeAccumulator >= nextEventTime {
                    spawnPhysicalGrain()
                    nextEventTime = timeAccumulator + period * Double.random(in: 0.994...1.006)
                }

            case .barberScissors:
                // Realistic barber hand snipping cadence: rhythmic clusters of 2-5 snips followed by a comb pause
                if timeAccumulator >= nextEventTime {
                    if snipBurstRemaining <= 0 {
                        snipBurstRemaining = Int.random(in: 2...5)
                    }
                    spawnPhysicalGrain(velocity: Float.random(in: 0.38...0.68))
                    snipBurstRemaining -= 1
                    if snipBurstRemaining > 0 {
                        nextEventTime = timeAccumulator + Double.random(in: 0.16...0.28)
                    } else {
                        nextEventTime = timeAccumulator + Double.random(in: 0.75...1.65)
                    }
                }

            default:
                // Stochastic Poisson process for raindrops, campfire embers, and comb bristles
                let prob = density / sr
                if Float.random(in: 0.0...1.0) < prob {
                    spawnPhysicalGrain()
                }
            }

            var sum: Float = 0.0
            var writeIdx = 0

            for idx in 0..<grains.count {
                var g = grains[idx]
                g.modeFreq2 = min(sr * 0.44, g.modeFreq2 * g.chirpRate)
                g.phase1 += g.modeFreq1 * twoPi / sr
                g.phase2 += g.modeFreq2 * twoPi / sr
                if g.phase1 > twoPi { g.phase1 -= twoPi }
                if g.phase2 > twoPi { g.phase2 -= twoPi }

                let modalTone = (sin(g.phase1) * 0.65 + sin(g.phase2) * 0.35) * g.toneAmp
                g.toneAmp *= g.toneDecay

                // Filtered physical impact / friction burst
                let white = Float.random(in: -1.0...1.0)
                g.noiseFilter = 0.55 * g.noiseFilter + 0.45 * white
                let noiseBurst = (white - g.noiseFilter * 0.5) * g.noiseAmp
                g.noiseAmp *= g.noiseDecay

                sum += modalTone + noiseBurst

                if g.toneAmp > 0.0005 || g.noiseAmp > 0.0005 {
                    grains[writeIdx] = g
                    writeIdx += 1
                }
            }
            if writeIdx < grains.count {
                grains.removeSubrange(writeIdx..<grains.count)
            }

            // Subtle continuous acoustic bed for rain or hearth fire
            var bed: Float = 0.0
            if type == .raindrop || type == .campfire {
                let w = Float.random(in: -1.0...1.0)
                velvetBedState = 0.92 * velvetBedState + 0.08 * w
                bed = velvetBedState * 0.035
            }

            buffer[i] += sum * 0.42 + bed
        }
    }
}

// MARK: - 5. Warm Acoustic Harmonium / Sub-Bass Resonator Voice

public final class SubtractiveDroneVoice: DSPVoice, @unchecked Sendable {
    public var fundamentalFreq: Float = 98.0
    public var detuneCents: Float = 6.0
    public var filterCutoff: Float = 360.0
    public var lfoRate: Float = 0.07

    private var phase1: Float = 0
    private var phase2: Float = 0
    private var phaseSub: Float = 0
    private var phaseFifth: Float = 0
    private var lfoPhase: Float = 0
    private var lp1: Float = 0
    private var lp2: Float = 0
    private var breathNoiseLP: Float = 0

    public init(fundamental: Float = 98.0) {
        self.fundamentalFreq = fundamental
    }

    public func triggerNote(pitchHz: Float, velocity: Float) {
        self.fundamentalFreq = pitchHz
    }

    public func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let sr = Float(sampleRate)
        let f1 = fundamentalFreq
        let f2 = fundamentalFreq * pow(2.0, detuneCents / 1200.0)
        let fSub = fundamentalFreq * 0.5
        let fFifth = fundamentalFreq * 1.4983

        for i in 0..<frameCount {
            lfoPhase += lfoRate * 2.0 * Float.pi / sr
            if lfoPhase > Float.pi * 2.0 { lfoPhase -= Float.pi * 2.0 }

            let breathSwell = 0.82 + 0.18 * sin(lfoPhase)
            let cutoff = filterCutoff * (0.85 + 0.25 * sin(lfoPhase))
            let alpha = min(0.25, (2.0 * Float.pi * cutoff) / sr)

            phase1 += f1 * 2.0 * Float.pi / sr
            phase2 += f2 * 2.0 * Float.pi / sr
            phaseSub += fSub * 2.0 * Float.pi / sr
            phaseFifth += fFifth * 2.0 * Float.pi / sr
            if phase1 > Float.pi * 2.0 { phase1 -= Float.pi * 2.0 }
            if phase2 > Float.pi * 2.0 { phase2 -= Float.pi * 2.0 }
            if phaseSub > Float.pi * 2.0 { phaseSub -= Float.pi * 2.0 }
            if phaseFifth > Float.pi * 2.0 { phaseFifth -= Float.pi * 2.0 }

            // Warm reed/cello wave shaping
            let s1 = tanh(sin(phase1) * 1.4) * 0.38
            let s2 = tanh(sin(phase2) * 1.4) * 0.35
            let sSub = sin(phaseSub) * 0.42
            let sFifth = sin(phaseFifth) * 0.14

            // Subtle organic reed/bellows air texture
            let w = Float.random(in: -1.0...1.0)
            breathNoiseLP = 0.96 * breathNoiseLP + 0.04 * w

            let raw = (s1 + s2 + sSub + sFifth + breathNoiseLP * 0.05) * breathSwell
            lp1 += alpha * (raw - lp1)
            lp2 += alpha * (lp1 - lp2)

            buffer[i] += lp2 * 0.36
        }
    }
}

// MARK: - 6. Vintage Mainframe & Electromechanical Relay Voice

public final class VintageMainframeVoice: DSPVoice, @unchecked Sendable {
    public var density: Float = 14.0
    public var seekRate: Float = 4.0
    public var spindleHumFreq: Float = 120.0

    private struct MechanicalActuatorImpact {
        var coilFreq: Float
        var chassisFreq: Float
        var phaseCoil: Float = 0
        var phaseChassis: Float = 0
        var amp: Float
        var decay: Float
        var snapAmp: Float
    }

    private var impacts: [MechanicalActuatorImpact] = []
    private var spindlePhase: Float = 0
    private var airNoiseLP: Float = 0
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
        spawnImpact(freq: pitchHz, velocity: velocity)
    }

    private func spawnImpact(freq: Float? = nil, velocity: Float? = nil) {
        guard impacts.count < 16 else { return }
        let f = freq ?? Float.random(in: 1100...2400)
        let chassisF = Float.random(in: 110...210)
        let v = velocity ?? Float.random(in: 0.35...0.75)
        impacts.append(MechanicalActuatorImpact(
            coilFreq: f,
            chassisFreq: chassisF,
            amp: v,
            decay: Float.random(in: 0.978...0.989),
            snapAmp: v * 0.85
        ))
    }

    public func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let sr = Float(sampleRate)
        let dt = 1.0 / sampleRate

        for i in 0..<frameCount {
            timeAccumulator += dt

            spindlePhase += spindleHumFreq * 2.0 * Float.pi / sr
            if spindlePhase > Float.pi * 2.0 { spindlePhase -= Float.pi * 2.0 }
            let w = Float.random(in: -1.0...1.0)
            airNoiseLP = 0.88 * airNoiseLP + 0.12 * w
            let hum = sin(spindlePhase) * 0.03 + sin(spindlePhase * 2.0) * 0.018 + airNoiseLP * 0.015

            if !inBurst && (timeAccumulator - lastBurstTime) >= Double(1.0 / max(0.5, seekRate)) {
                lastBurstTime = timeAccumulator
                inBurst = true
                burstRemainingClicks = Int.random(in: 3...7)
                nextClickTime = timeAccumulator
            }

            if inBurst && timeAccumulator >= nextClickTime {
                spawnImpact(velocity: Float.random(in: 0.4...0.8))
                burstRemainingClicks -= 1
                if burstRemainingClicks <= 0 {
                    inBurst = false
                } else {
                    nextClickTime = timeAccumulator + Double.random(in: 0.028...0.068)
                }
            }

            var sum: Float = 0
            var writeIdx = 0
            for idx in 0..<impacts.count {
                var c = impacts[idx]
                c.phaseCoil += c.coilFreq * 2.0 * Float.pi / sr
                c.phaseChassis += c.chassisFreq * 2.0 * Float.pi / sr
                let snap = Float.random(in: -1.0...1.0) * c.snapAmp
                c.snapAmp *= 0.92
                let body = (sin(c.phaseCoil) * 0.35 + sin(c.phaseChassis) * 0.65) * c.amp + snap
                c.amp *= c.decay
                sum += body

                if c.amp > 0.001 {
                    impacts[writeIdx] = c
                    writeIdx += 1
                }
            }
            if writeIdx < impacts.count {
                impacts.removeSubrange(writeIdx..<impacts.count)
            }

            buffer[i] += (sum * 0.45 + hum) * 0.6
        }
    }
}
