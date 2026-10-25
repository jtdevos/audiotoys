import Foundation
import AVFoundation

/// Streams real recorded audio files with seamless equal-power crossfade looping,
/// Hermite-interpolated micro-pitch humanization, and multi-slice round-robin triggering
/// to eliminate mechanical repetition and loop boundary clicks.
public final class OrganicSampleStreamer: DSPVoice, @unchecked Sendable {
    private let samples: [Float]
    private let fileSampleRate: Double
    public let isLooping: Bool
    public var triggerInterval: Double

    // Playback heads (primary + crossfade secondary head for seamless looping)
    private var readPosA: Double = 0.0
    private var readPosB: Double = 0.0
    private var isPlayingA: Bool = false
    private var isPlayingB: Bool = false

    // Organic humanization parameters
    private var rateA: Double = 1.0
    private var rateB: Double = 1.0
    private var gainA: Float = 1.0
    private var gainB: Float = 1.0

    // For periodic one-shot / slice triggering
    private var timeAccumulator: Double = 0.0
    private var nextTriggerTime: Double = 0.0
    private var slicePlayDuration: Double = 0.0
    private var sliceElapsed: Double = 0.0

    public init?(fileURL: URL, isLooping: Bool, interval: Double) {
        guard let audioFile = try? AVAudioFile(forReading: fileURL) else {
            return nil
        }
        let format = audioFile.processingFormat
        let frameCount = AVAudioFrameCount(audioFile.length)
        guard frameCount > 0,
              let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        do {
            try audioFile.read(into: pcmBuffer)
        } catch {
            return nil
        }

        let actualFrames = Int(pcmBuffer.frameLength)
        guard actualFrames > 0, let channelData = pcmBuffer.floatChannelData else {
            return nil
        }

        let chCount = Int(format.channelCount)
        var mono = [Float](repeating: 0.0, count: actualFrames)
        if chCount == 1 {
            let ptr = channelData[0]
            for i in 0..<actualFrames {
                mono[i] = ptr[i]
            }
        } else {
            let scale = 1.0 / Float(chCount)
            for c in 0..<chCount {
                let ptr = channelData[c]
                for i in 0..<actualFrames {
                    mono[i] += ptr[i] * scale
                }
            }
        }

        self.samples = mono
        self.fileSampleRate = format.sampleRate
        self.isLooping = isLooping
        self.triggerInterval = interval

        if isLooping {
            self.isPlayingA = true
            // Start at a slight random phase so multiple layers don't align mechanically
            self.readPosA = Double.random(in: 0.0..<(Double(actualFrames) * 0.25))
            self.rateA = Double.random(in: 0.985...1.015)
        } else {
            // Trigger first event shortly after start
            self.nextTriggerTime = Double.random(in: 0.05...0.45)
        }
    }

    public func triggerNote(pitchHz: Float, velocity: Float) {
        triggerOrganicSlice(velocity: velocity)
    }

    private func triggerOrganicSlice(velocity: Float = 0.95) {
        guard !samples.isEmpty else { return }
        let totalDur = Double(samples.count) / fileSampleRate

        // Humanize pitch/speed slightly on each trigger (0.95x to 1.05x)
        rateA = Double.random(in: 0.955...1.045)
        gainA = velocity * Float.random(in: 0.88...1.04)

        // If the sample is a longer foley recording (> 4.5s) and triggered periodically,
        // pick an organic window within the recording for natural round-robin variety
        if totalDur > 4.8 && triggerInterval > 0 && triggerInterval < totalDur {
            let windowDur = min(totalDur * 0.65, max(2.2, triggerInterval * 0.88))
            let maxStart = max(0.0, totalDur - windowDur - 0.1)
            let startSec = Double.random(in: 0.0...maxStart)
            readPosA = startSec * fileSampleRate
            slicePlayDuration = windowDur
        } else {
            readPosA = 0.0
            slicePlayDuration = totalDur
        }
        sliceElapsed = 0.0
        isPlayingA = true
    }

    public func render(buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let count = samples.count
        guard count > 8 else { return }

        let dt = 1.0 / sampleRate
        let baseStep = fileSampleRate / sampleRate
        let totalFramesDouble = Double(count)

        if isLooping {
            // Equal-power crossfade region (0.40 seconds before the end of the file)
            let xfadeFrames = min(Double(count) * 0.22, 0.40 * fileSampleRate)
            let loopTriggerPoint = totalFramesDouble - xfadeFrames

            for i in 0..<frameCount {
                var out: Float = 0.0

                if isPlayingA {
                    let sA = hermiteSample(at: readPosA)
                    var envA: Float = 1.0

                    if readPosA >= loopTriggerPoint {
                        // Start B if not already crossfading
                        if !isPlayingB {
                            isPlayingB = true
                            readPosB = 0.0
                            rateB = Double.random(in: 0.982...1.018)
                        }
                        let fadeProgress = Float((readPosA - loopTriggerPoint) / max(1.0, xfadeFrames))
                        let clamped = max(0.0, min(1.0, fadeProgress))
                        envA = cos(clamped * Float.pi * 0.5)
                    }

                    out += sA * envA * gainA
                    readPosA += baseStep * rateA

                    if readPosA >= totalFramesDouble - 2 {
                        // Promote B to A
                        readPosA = readPosB
                        rateA = rateB
                        isPlayingB = false
                    }
                }

                if isPlayingB {
                    let sB = hermiteSample(at: readPosB)
                    let fadeProgress = Float(readPosB / max(1.0, xfadeFrames))
                    let clamped = max(0.0, min(1.0, fadeProgress))
                    let envB = sin(clamped * Float.pi * 0.5)
                    out += sB * envB * gainB
                    readPosB += baseStep * rateB
                }

                buffer[i] += out
            }
        } else {
            // Periodic / One-Shot Foley Streamer with humanized intervals and smooth window envelopes
            for i in 0..<frameCount {
                timeAccumulator += dt

                if triggerInterval > 0 && timeAccumulator >= nextTriggerTime {
                    triggerOrganicSlice(velocity: Float.random(in: 0.85...1.0))
                    // Add organic human timing jitter (±16%)
                    let jitteredInterval = triggerInterval * Double.random(in: 0.84...1.16)
                    nextTriggerTime = timeAccumulator + max(0.35, jitteredInterval)
                }

                if isPlayingA {
                    let s = hermiteSample(at: readPosA)

                    // Smooth 35ms fade-in and 80ms fade-out on slices so there is never a click
                    let fadeInDur = 0.035
                    let fadeOutDur = 0.085
                    var env: Float = 1.0
                    if sliceElapsed < fadeInDur {
                        env = Float(sliceElapsed / fadeInDur)
                    } else if sliceElapsed > (slicePlayDuration - fadeOutDur) {
                        let rem = max(0.0, slicePlayDuration - sliceElapsed)
                        env = Float(rem / fadeOutDur)
                    }

                    buffer[i] += s * env * gainA

                    readPosA += baseStep * rateA
                    sliceElapsed += dt

                    if readPosA >= totalFramesDouble - 4 || sliceElapsed >= slicePlayDuration {
                        isPlayingA = false
                    }
                }
            }
        }
    }

    /// 4-point, 3rd-order Hermite cubic interpolation for artifact-free varispeed playback.
    @inline(__always)
    private func hermiteSample(at pos: Double) -> Float {
        let count = samples.count
        let idx1 = Int(pos)
        guard idx1 >= 0 && idx1 < count else { return 0.0 }
        let frac = Float(pos - Double(idx1))

        let idx0 = max(0, idx1 - 1)
        let idx2 = min(count - 1, idx1 + 1)
        let idx3 = min(count - 1, idx1 + 2)

        let y0 = samples[idx0]
        let y1 = samples[idx1]
        let y2 = samples[idx2]
        let y3 = samples[idx3]

        let c0 = y1
        let c1 = 0.5 * (y2 - y0)
        let c2 = y0 - 2.5 * y1 + 2.0 * y2 - 0.5 * y3
        let c3 = 0.5 * (y3 - y0) + 1.5 * (y1 - y2)

        return ((c3 * frac + c2) * frac + c1) * frac + c0
    }
}
