import Foundation
import CoreMotion

/// Tracks real-time AirPods Pro / Max head orientation (yaw, pitch, roll) via CoreMotion.
public final class HeadphoneMotionTracker: NSObject, CMHeadphoneMotionManagerDelegate, @unchecked Sendable {
    private var motionManager: CMHeadphoneMotionManager?
    private let queue = OperationQueue()

    public private(set) var isTracking: Bool = false
    public private(set) var isConnected: Bool = false

    private var rawYawDeg: Float = 0.0
    private var rawPitchDeg: Float = 0.0
    private var rawRollDeg: Float = 0.0
    private var referenceYawDeg: Float = 0.0

    public var onOrientationUpdate: ((_ yawDeg: Float, _ pitchDeg: Float, _ rollDeg: Float) -> Void)?
    public var onConnectionChange: ((_ connected: Bool) -> Void)?

    public override init() {
        super.init()
        queue.name = "com.audiotoys.headphone-motion"
        queue.maxConcurrentOperationCount = 1
    }

    /// Checks whether the current process bundle includes `NSMotionUsageDescription` required by macOS TCC.
    public var hasMotionUsageDescription: Bool {
        Bundle.main.object(forInfoDictionaryKey: "NSMotionUsageDescription") != nil
    }

    public func start() {
        guard !isTracking else { return }
        isTracking = true

        guard hasMotionUsageDescription else {
            // Running as raw CLI binary without app bundle Info.plist;
            // keep manual head orientation active without invoking TCC.
            return
        }

        let manager = motionManager ?? CMHeadphoneMotionManager()
        motionManager = manager
        manager.delegate = self

        if manager.isDeviceMotionAvailable {
            manager.startConnectionStatusUpdates()
            manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
                guard let self = self, let motion = motion, error == nil else { return }
                let radToDeg = Float(180.0 / Double.pi)
                // CoreMotion attitude yaw is counter-clockwise; AVAudioEngine yaw is clockwise in degrees
                let yaw = Float(-motion.attitude.yaw) * radToDeg
                let pitch = Float(motion.attitude.pitch) * radToDeg
                let roll = Float(motion.attitude.roll) * radToDeg

                self.rawYawDeg = yaw
                self.rawPitchDeg = pitch
                self.rawRollDeg = roll

                let relativeYaw = self.normalizeDegrees(yaw - self.referenceYawDeg)
                DispatchQueue.main.async {
                    if !self.isConnected {
                        self.isConnected = true
                        self.onConnectionChange?(true)
                    }
                    self.onOrientationUpdate?(relativeYaw, pitch, roll)
                }
            }
        }
    }

    public func stop() {
        guard isTracking else { return }
        isTracking = false
        if let manager = motionManager {
            manager.stopDeviceMotionUpdates()
            manager.stopConnectionStatusUpdates()
        }
        isConnected = false
        onConnectionChange?(false)
    }

    public func recenter() {
        referenceYawDeg = rawYawDeg
        onOrientationUpdate?(0.0, 0.0, 0.0)
    }

    public func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = true
            self?.onConnectionChange?(true)
        }
    }

    public func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
            self?.onConnectionChange?(false)
        }
    }

    private func normalizeDegrees(_ deg: Float) -> Float {
        var d = fmod(deg, 360.0)
        if d > 180.0 { d -= 360.0 }
        if d < -180.0 { d += 360.0 }
        return d
    }
}
