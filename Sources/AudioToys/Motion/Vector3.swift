import Foundation
import simd

/// A 3D vector representing coordinates (x, y, z) in meters relative to the listener.
/// X: Left (-X) to Right (+X)
/// Y: Below (-Y) to Above (+Y)
/// Z: Forward (-Z) to Behind (+Z)
/// Note: AVFoundation spatial audio uses:
/// Listener at origin (0, 0, 0), facing -Z (forward), +Y is up, +X is right.
public struct Vector3: Codable, Equatable, Hashable {
    public var x: Float
    public var y: Float
    public var z: Float

    public static let zero = Vector3(x: 0, y: 0, z: 0)
    public static let forward = Vector3(x: 0, y: 0, z: -1)
    public static let up = Vector3(x: 0, y: 1, z: 0)
    public static let right = Vector3(x: 1, y: 0, z: 0)

    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    public var length: Float {
        sqrt(x * x + y * y + z * z)
    }

    public var horizontalDistance: Float {
        sqrt(x * x + z * z)
    }

    public var normalized: Vector3 {
        let len = length
        guard len > 0.0001 else { return .zero }
        return Vector3(x: x / len, y: y / len, z: z / len)
    }

    public static func + (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    public static func - (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    public static func * (lhs: Vector3, scalar: Float) -> Vector3 {
        Vector3(x: lhs.x * scalar, y: lhs.y * scalar, z: lhs.z * scalar)
    }

    public static func * (scalar: Float, rhs: Vector3) -> Vector3 {
        rhs * scalar
    }

    public static func / (lhs: Vector3, scalar: Float) -> Vector3 {
        Vector3(x: lhs.x / scalar, y: lhs.y / scalar, z: lhs.z / scalar)
    }

    public static func lerp(from: Vector3, to: Vector3, t: Float) -> Vector3 {
        let clampedT = max(0, min(1, t))
        return from + (to - from) * clampedT
    }

    public static func distance(_ a: Vector3, _ b: Vector3) -> Float {
        (a - b).length
    }
}

extension Vector3: CustomStringConvertible {
    public var description: String {
        String(format: "(x: %.2f, y: %.2f, z: %.2f)", x, y, z)
    }
}
