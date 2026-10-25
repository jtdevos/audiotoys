import Foundation

/// Defines the acoustic tone-sculpting and filter character for a spatial audio layer.
public enum AcousticProfile: String, Codable, CaseIterable, Sendable {
    case intimateASMR = "Intimate ASMR"
    case crispShears = "Crisp Steel Shears"
    case velvetBrush = "Velvet Brush & Comb"
    case warmMotor = "Warm Rotary Clippers"
    case naturalFoley = "Natural Studio Foley"
    case resonantWood = "Resonant Wood & Hearth"
    case crystalline = "Crystalline Harmonic"
    case deepSub = "Deep Subterranean"
}

/// Real-time 5-stage acoustic DSP filter chain applied to each spatial audio layer.
///
/// Stages:
/// 1. High-Pass Rumble & DC Blocker (2nd-order Butterworth HPF)
/// 2. Dynamic Binaural Proximity Bass Shelf (165 Hz low-shelf boosted when source < 0.85m from ear)
/// 3. Acoustic Character Parametric Bell EQ (sculpts material formants: steel, bristles, wood, motor)
/// 4. Dynamic Near-Field Air Exciter (7.8 kHz high-shelf) + Far-Field Distance Air Absorption (LPF)
/// 5. Transient Micro-Detail Enhancer & Warm Triode/Tape Soft-Clipper (`tanh`)
public final class AcousticFilterChain: @unchecked Sendable {
    public var profile: AcousticProfile
    public var proximityIntensity: Float = 1.0

    // Distance in meters from listener (0,0,0), updated at 60Hz from 3D position
    public private(set) var currentDistance: Float = 1.0
    public private(set) var proximityFactor: Float = 0.0 // 0.0 (far) -> 1.0 (ear-level 0.12m)
    public private(set) var rearShadowFactor: Float = 0.0 // 0.0 (front) -> 1.0 (directly behind head)

    // Real-time metering output
    public private(set) var lastRMS: Float = 0.0
    public private(set) var lastPeak: Float = 0.0

    // Biquad filter states (Direct Form II Transposed for numerical stability)
    private struct BiquadState {
        var b0: Float = 1.0, b1: Float = 0.0, b2: Float = 0.0
        var a1: Float = 0.0, a2: Float = 0.0
        var z1: Float = 0.0, z2: Float = 0.0

        @inline(__always)
        mutating func process(_ x: Float) -> Float {
            let y = b0 * x + z1
            z1 = b1 * x - a1 * y + z2
            z2 = b2 * x - a2 * y
            return y
        }
    }

    private var hpfStage = BiquadState()
    private var proximityShelfStage = BiquadState()
    private var bodyBellStage = BiquadState()
    private var airShelfStage = BiquadState()
    private var airAbsorptionLPFStage = BiquadState()

    // Transient shaper envelope followers
    private var fastEnv: Float = 0.0
    private var slowEnv: Float = 0.0

    private var cachedSampleRate: Float = 44100.0
    private var needsCoefficientUpdate: Bool = true

    public init(profile: AcousticProfile = .naturalFoley) {
        self.profile = profile
        updateCoefficients(sampleRate: 44100.0)
    }

    /// Updates 3D position relative to the listener, computing both near-field proximity effect
    /// and pinna front/back directional spectral cues.
    public func updateSpatialPosition(_ pos: Vector3) {
        let dist = max(0.08, min(15.0, pos.magnitude))
        // In CoreAudio 3D coordinates, -Z is Front (Nose) and +Z is Behind the head
        let normalizedZ = pos.z / dist // -1.0 = dead front, +1.0 = dead behind
        let newRear = max(0.0, normalizedZ)

        if abs(dist - currentDistance) > 0.004 || abs(newRear - rearShadowFactor) > 0.01 {
            currentDistance = dist
            rearShadowFactor = newRear
            let rawProx = max(0.0, min(1.0, (0.85 - dist) / (0.85 - 0.12)))
            proximityFactor = rawProx * rawProx
            needsCoefficientUpdate = true
        }
    }

    /// Updates spatial distance from the listener and recalculates dynamic proximity & air absorption filters.
    public func updateSpatialDistance(_ distanceMeters: Float) {
        updateSpatialPosition(Vector3(distanceMeters, 0, 0))
    }

    public func setProfile(_ newProfile: AcousticProfile) {
        if profile != newProfile {
            profile = newProfile
            needsCoefficientUpdate = true
        }
    }

    /// Processes a mono audio buffer in-place through the 5-stage acoustic filter chain.
    public func process(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let sr = Float(sampleRate)
        if abs(sr - cachedSampleRate) > 1.0 || needsCoefficientUpdate {
            cachedSampleRate = sr
            updateCoefficients(sampleRate: sr)
            needsCoefficientUpdate = false
        }

        let transientAmount: Float
        let saturationDrive: Float
        switch profile {
        case .crispShears:
            transientAmount = 0.28
            saturationDrive = 1.18
        case .intimateASMR, .velvetBrush:
            transientAmount = 0.22
            saturationDrive = 1.15
        case .resonantWood:
            transientAmount = 0.25
            saturationDrive = 1.22
        case .warmMotor:
            transientAmount = 0.05
            saturationDrive = 1.30
        default:
            transientAmount = 0.12
            saturationDrive = 1.10
        }

        let fastAlpha: Float = 1.0 - exp(-1.0 / (0.0008 * sr))
        let slowAlpha: Float = 1.0 - exp(-1.0 / (0.028 * sr))
        let proxBoost = proximityFactor * proximityIntensity

        var sumSquares: Float = 0.0
        var peak: Float = 0.0

        for i in 0..<frameCount {
            var s = buffer[i]

            // Stage 1: High-pass rumble filter
            s = hpfStage.process(s)

            // Stage 2: Dynamic Binaural Proximity Bass Shelf
            s = proximityShelfStage.process(s)

            // Stage 3: Acoustic Character Body Bell EQ
            s = bodyBellStage.process(s)

            // Stage 4a: Dynamic Near-Field Air Presence Shelf
            s = airShelfStage.process(s)

            // Stage 4b: Distance Air Absorption Low-Pass Filter
            s = airAbsorptionLPFStage.process(s)

            // Stage 5a: Micro-Transient Shaper (brings out crisp ASMR snaps, snips, and bristle clicks)
            let absS = abs(s)
            fastEnv += fastAlpha * (absS - fastEnv)
            slowEnv += slowAlpha * (absS - slowEnv)
            let diff = max(0.0, fastEnv - slowEnv)
            let transientGain = 1.0 + diff * (transientAmount + proxBoost * 0.20) * 4.5
            s *= min(1.65, transientGain)

            // Stage 5b: Subtle near-field presence gain + Warm asymmetric tape/triode saturation
            let nearFieldGain: Float = 1.0 + proxBoost * 0.22
            let driven = s * nearFieldGain * saturationDrive
            // Fast rational tanh approximation with subtle warm 2nd-harmonic asymmetry
            let asym = driven + 0.04 * driven * abs(driven)
            let out = Float(tanh(Double(asym))) / saturationDrive * 1.05

            buffer[i] = out
            sumSquares += out * out
            if abs(out) > peak {
                peak = abs(out)
            }
        }

        if frameCount > 0 {
            lastRMS = sqrt(sumSquares / Float(frameCount))
            lastPeak = peak
        }
    }

    // MARK: - Filter Coefficient Design (Audio EQ Cookbook)

    private func updateCoefficients(sampleRate sr: Float) {
        let prox = proximityFactor * proximityIntensity

        // 1. High-Pass Filter cutoff by profile
        let hpfFreq: Float
        let bodyFreq: Float
        let bodyQ: Float
        let bodyGainDB: Float
        let baseAirGainDB: Float

        switch profile {
        case .intimateASMR:
            hpfFreq = 65.0
            bodyFreq = 210.0
            bodyQ = 1.1
            bodyGainDB = 2.5
            baseAirGainDB = 3.2
        case .crispShears:
            hpfFreq = 135.0
            bodyFreq = 5200.0
            bodyQ = 1.25
            bodyGainDB = 3.8
            baseAirGainDB = 4.2
        case .velvetBrush:
            hpfFreq = 85.0
            bodyFreq = 260.0
            bodyQ = 1.15
            bodyGainDB = 2.8
            baseAirGainDB = 3.5
        case .warmMotor:
            hpfFreq = 55.0
            bodyFreq = 135.0
            bodyQ = 1.3
            bodyGainDB = 4.2
            baseAirGainDB = -1.5
        case .resonantWood:
            hpfFreq = 70.0
            bodyFreq = 320.0
            bodyQ = 1.2
            bodyGainDB = 3.5
            baseAirGainDB = 1.8
        case .crystalline:
            hpfFreq = 110.0
            bodyFreq = 3400.0
            bodyQ = 1.4
            bodyGainDB = 2.5
            baseAirGainDB = 2.8
        case .deepSub:
            hpfFreq = 28.0
            bodyFreq = 62.0
            bodyQ = 1.1
            bodyGainDB = 4.5
            baseAirGainDB = -2.0
        case .naturalFoley:
            hpfFreq = 75.0
            bodyFreq = 1800.0
            bodyQ = 0.9
            bodyGainDB = 1.2
            baseAirGainDB = 1.5
        }

        configureHighPass(&hpfStage, freq: hpfFreq, q: 0.707, sr: sr)

        // 2. Dynamic Binaural Proximity Low-Shelf at 165 Hz (up to +7.5 dB when right next to the ear, plus subtle occipital warmth behind the head)
        let proxLowGainDB = prox * 7.5 + rearShadowFactor * 1.4
        configureLowShelf(&proximityShelfStage, freq: 165.0, gainDB: proxLowGainDB, sr: sr)

        // 3. Acoustic Character Body Parametric Bell
        configurePeakingEQ(&bodyBellStage, freq: bodyFreq, q: bodyQ, gainDB: bodyGainDB, sr: sr)

        // 4a. Dynamic Near-Field Air High-Shelf at 7500 Hz (with pinna shadow when behind the head +Z)
        let totalAirGainDB = baseAirGainDB + prox * 4.8 - rearShadowFactor * 2.8
        configureHighShelf(&airShelfStage, freq: 7500.0, gainDB: totalAirGainDB, sr: sr)

        // 4b. Distance Air Absorption + Pinna Rear Shadow Low-Pass Filter
        // Near (<0.7m): 19.5 kHz (wide open). Behind head or far (4m+): smoothly shades high frequencies.
        let distFactor = max(0.0, min(1.0, (currentDistance - 0.6) / 4.5))
        let rearLPFScale: Float = 1.0 - rearShadowFactor * 0.32
        let lpfCutoff = (19500.0 * pow(3200.0 / 19500.0, distFactor)) * rearLPFScale
        configureLowPass(&airAbsorptionLPFStage, freq: min(sr * 0.46, lpfCutoff), q: 0.707, sr: sr)
    }

    private func configureHighPass(_ state: inout BiquadState, freq: Float, q: Float, sr: Float) {
        let w0 = 2.0 * Float.pi * max(20.0, min(sr * 0.45, freq)) / sr
        let cosW = cos(w0)
        let alpha = sin(w0) / (2.0 * q)
        let a0 = 1.0 + alpha
        state.b0 = ((1.0 + cosW) * 0.5) / a0
        state.b1 = -(1.0 + cosW) / a0
        state.b2 = ((1.0 + cosW) * 0.5) / a0
        state.a1 = (-2.0 * cosW) / a0
        state.a2 = (1.0 - alpha) / a0
    }

    private func configureLowPass(_ state: inout BiquadState, freq: Float, q: Float, sr: Float) {
        let w0 = 2.0 * Float.pi * max(80.0, min(sr * 0.47, freq)) / sr
        let cosW = cos(w0)
        let alpha = sin(w0) / (2.0 * q)
        let a0 = 1.0 + alpha
        state.b0 = ((1.0 - cosW) * 0.5) / a0
        state.b1 = (1.0 - cosW) / a0
        state.b2 = ((1.0 - cosW) * 0.5) / a0
        state.a1 = (-2.0 * cosW) / a0
        state.a2 = (1.0 - alpha) / a0
    }

    private func configurePeakingEQ(_ state: inout BiquadState, freq: Float, q: Float, gainDB: Float, sr: Float) {
        let A = pow(10.0, gainDB / 40.0)
        let w0 = 2.0 * Float.pi * max(40.0, min(sr * 0.45, freq)) / sr
        let cosW = cos(w0)
        let alpha = sin(w0) / (2.0 * q)
        let a0 = 1.0 + alpha / A
        state.b0 = (1.0 + alpha * A) / a0
        state.b1 = (-2.0 * cosW) / a0
        state.b2 = (1.0 - alpha * A) / a0
        state.a1 = (-2.0 * cosW) / a0
        state.a2 = (1.0 - alpha / A) / a0
    }

    private func configureLowShelf(_ state: inout BiquadState, freq: Float, gainDB: Float, sr: Float) {
        let A = pow(10.0, gainDB / 40.0)
        let w0 = 2.0 * Float.pi * max(30.0, min(sr * 0.45, freq)) / sr
        let cosW = cos(w0)
        let sinW = sin(w0)
        let sqrtA2Alpha = 2.0 * sqrt(A) * (sinW / 2.0)
        let a0 = (A + 1.0) + (A - 1.0) * cosW + sqrtA2Alpha
        state.b0 = (A * ((A + 1.0) - (A - 1.0) * cosW + sqrtA2Alpha)) / a0
        state.b1 = (2.0 * A * ((A - 1.0) - (A + 1.0) * cosW)) / a0
        state.b2 = (A * ((A + 1.0) - (A - 1.0) * cosW - sqrtA2Alpha)) / a0
        state.a1 = (-2.0 * ((A - 1.0) + (A + 1.0) * cosW)) / a0
        state.a2 = ((A + 1.0) + (A - 1.0) * cosW - sqrtA2Alpha) / a0
    }

    private func configureHighShelf(_ state: inout BiquadState, freq: Float, gainDB: Float, sr: Float) {
        let A = pow(10.0, gainDB / 40.0)
        let w0 = 2.0 * Float.pi * max(500.0, min(sr * 0.45, freq)) / sr
        let cosW = cos(w0)
        let sinW = sin(w0)
        let sqrtA2Alpha = 2.0 * sqrt(A) * (sinW / 2.0)
        let a0 = (A + 1.0) - (A - 1.0) * cosW + sqrtA2Alpha
        state.b0 = (A * ((A + 1.0) + (A - 1.0) * cosW + sqrtA2Alpha)) / a0
        state.b1 = (-2.0 * A * ((A - 1.0) + (A + 1.0) * cosW)) / a0
        state.b2 = (A * ((A + 1.0) + (A - 1.0) * cosW - sqrtA2Alpha)) / a0
        state.a1 = (2.0 * ((A - 1.0) - (A + 1.0) * cosW)) / a0
        state.a2 = ((A + 1.0) - (A - 1.0) * cosW - sqrtA2Alpha) / a0
    }
}
