import Foundation

/// Defines how a 3D audio source moves through space over time.
public final class MotionScript: Codable, @unchecked Sendable {
    public enum MotionType: String, Codable {
        case fixed
        case orbit
        case spiral
        case lissajous
        case pendulum
        case wander
        case flyby
        case customExpr
    }

    public var type: MotionType
    public var rawScript: String

    // Parameters for built-in trajectories
    public var radius: Float = 2.0
    public var minRadius: Float = 0.5
    public var maxRadius: Float = 3.5
    public var speed: Float = 0.5
    public var height: Float = 0.0
    public var verticalSpeed: Float = 0.2
    public var verticalAmplitude: Float = 0.5
    public var phase: Float = 0.0

    // Lissajous parameters
    public var xRadius: Float = 2.0
    public var yRadius: Float = 0.5
    public var zRadius: Float = 2.0
    public var xFreq: Float = 0.5
    public var yFreq: Float = 0.8
    public var zFreq: Float = 0.3

    // Pendulum parameters
    public var pendulumLength: Float = 2.0
    public var pendulumAngleDeg: Float = 45.0
    public var pendulumFreq: Float = 0.8
    public var pendulumAxis: String = "x"

    // Wander parameters
    public var wanderJitter: Float = 0.3
    public var wanderBounds: Float = 4.0

    // Flyby parameters
    public var flybyStart: Vector3 = Vector3(-8, 0, 2)
    public var flybyEnd: Vector3 = Vector3(8, 0, 2)
    public var flybyDuration: Float = 5.0
    public var flybyPause: Float = 2.0

    // Fixed position
    public var fixedPosition: Vector3 = .zero

    // Custom expression parsers
    private var exprX: ExpressionEvaluator?
    private var exprY: ExpressionEvaluator?
    private var exprZ: ExpressionEvaluator?

    enum CodingKeys: String, CodingKey {
        case rawScript
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let script = try container.decode(String.self, forKey: .rawScript)
        self.rawScript = script
        self.type = .fixed
        self.parse(script: script)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawScript, forKey: .rawScript)
    }

    public init(type: MotionType = .fixed, script: String = "") {
        self.type = type
        self.rawScript = script
        if !script.isEmpty {
            self.parse(script: script)
        }
    }

    // MARK: - Factory Constructors

    public static func fixed(at pos: Vector3) -> MotionScript {
        let script = MotionScript(type: .fixed, script: "static x=\(pos.x) y=\(pos.y) z=\(pos.z)")
        script.fixedPosition = pos
        return script
    }

    public static func orbit(radius: Float = 2.0, speed: Float = 0.5, height: Float = 0.0, phase: Float = 0.0) -> MotionScript {
        let s = MotionScript(type: .orbit, script: "orbit radius=\(radius) speed=\(speed) height=\(height) phase=\(phase)")
        s.radius = radius
        s.speed = speed
        s.height = height
        s.phase = phase
        return s
    }

    public static func spiral(minR: Float = 0.5, maxR: Float = 3.5, speed: Float = 0.3, vSpeed: Float = 0.2, vAmp: Float = 0.5) -> MotionScript {
        let s = MotionScript(type: .spiral, script: "spiral min=\(minR) max=\(maxR) speed=\(speed) vSpeed=\(vSpeed) vAmp=\(vAmp)")
        s.minRadius = minR
        s.maxRadius = maxR
        s.speed = speed
        s.verticalSpeed = vSpeed
        s.verticalAmplitude = vAmp
        return s
    }

    public static func lissajous(xR: Float = 2.5, yR: Float = 0.8, zR: Float = 2.0, xF: Float = 0.5, yF: Float = 0.7, zF: Float = 0.3) -> MotionScript {
        let s = MotionScript(type: .lissajous, script: "lissajous xR=\(xR) yR=\(yR) zR=\(zR) xF=\(xF) yF=\(yF) zF=\(zF)")
        s.xRadius = xR
        s.yRadius = yR
        s.zRadius = zR
        s.xFreq = xF
        s.yFreq = yF
        s.zFreq = zF
        return s
    }

    public static func pendulum(length: Float = 2.0, angle: Float = 45.0, freq: Float = 0.8, axis: String = "x") -> MotionScript {
        let s = MotionScript(type: .pendulum, script: "pendulum length=\(length) angle=\(angle) freq=\(freq) axis=\(axis)")
        s.pendulumLength = length
        s.pendulumAngleDeg = angle
        s.pendulumFreq = freq
        s.pendulumAxis = axis
        return s
    }

    public static func wander(radius: Float = 3.0, speed: Float = 0.5, jitter: Float = 0.3) -> MotionScript {
        let s = MotionScript(type: .wander, script: "wander radius=\(radius) speed=\(speed) jitter=\(jitter)")
        s.radius = radius
        s.speed = speed
        s.wanderJitter = jitter
        return s
    }

    public static func flyby(start: Vector3, end: Vector3, duration: Float = 5.0, pause: Float = 2.0) -> MotionScript {
        let s = MotionScript(type: .flyby, script: "flyby start=[\(start.x),\(start.y),\(start.z)] end=[\(end.x),\(end.y),\(end.z)] duration=\(duration) pause=\(pause)")
        s.flybyStart = start
        s.flybyEnd = end
        s.flybyDuration = duration
        s.flybyPause = pause
        return s
    }

    public static func expression(x: String, y: String, z: String) -> MotionScript {
        let raw = "expr x=\(x); y=\(y); z=\(z)"
        let s = MotionScript(type: .customExpr, script: raw)
        s.setupExpressions(x: x, y: y, z: z)
        return s
    }

    // MARK: - Script Parsing

    public func parse(script: String) {
        self.rawScript = script.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmed = self.rawScript

        if trimmed.starts(with: "static") {
            self.type = .fixed
            let params = parseKeyValues(trimmed)
            if let x = params["x"], let y = params["y"], let z = params["z"] {
                self.fixedPosition = Vector3(x, y, z)
            }
        } else if trimmed.starts(with: "orbit") {
            self.type = .orbit
            let params = parseKeyValues(trimmed)
            if let r = params["radius"] ?? params["r"] { self.radius = r }
            if let sp = params["speed"] ?? params["s"] { self.speed = sp }
            if let h = params["height"] ?? params["h"] { self.height = h }
            if let p = params["phase"] { self.phase = p }
        } else if trimmed.starts(with: "spiral") {
            self.type = .spiral
            let params = parseKeyValues(trimmed)
            if let mn = params["min"] ?? params["minr"] { self.minRadius = mn }
            if let mx = params["max"] ?? params["maxr"] { self.maxRadius = mx }
            if let sp = params["speed"] { self.speed = sp }
            if let vs = params["vspeed"] { self.verticalSpeed = vs }
            if let va = params["vamp"] { self.verticalAmplitude = va }
        } else if trimmed.starts(with: "lissajous") {
            self.type = .lissajous
            let params = parseKeyValues(trimmed)
            if let xr = params["xr"] { self.xRadius = xr }
            if let yr = params["yr"] { self.yRadius = yr }
            if let zr = params["zr"] { self.zRadius = zr }
            if let xf = params["xf"] { self.xFreq = xf }
            if let yf = params["yf"] { self.yFreq = yf }
            if let zf = params["zf"] { self.zFreq = zf }
        } else if trimmed.starts(with: "pendulum") {
            self.type = .pendulum
            let params = parseKeyValues(trimmed)
            if let l = params["length"] ?? params["l"] { self.pendulumLength = l }
            if let a = params["angle"] ?? params["a"] { self.pendulumAngleDeg = a }
            if let f = params["freq"] ?? params["f"] { self.pendulumFreq = f }
            if let axis = parseStringValue(trimmed, key: "axis") { self.pendulumAxis = axis }
        } else if trimmed.starts(with: "wander") {
            self.type = .wander
            let params = parseKeyValues(trimmed)
            if let r = params["radius"] ?? params["r"] { self.radius = r }
            if let sp = params["speed"] ?? params["s"] { self.speed = sp }
            if let j = params["jitter"] ?? params["j"] { self.wanderJitter = j }
        } else if trimmed.starts(with: "flyby") {
            self.type = .flyby
            let params = parseKeyValues(trimmed)
            if let d = params["duration"] ?? params["d"] { self.flybyDuration = d }
            if let p = params["pause"] { self.flybyPause = p }
            if let startVec = parseVector(trimmed, key: "start") { self.flybyStart = startVec }
            if let endVec = parseVector(trimmed, key: "end") { self.flybyEnd = endVec }
        } else if trimmed.starts(with: "expr") {
            self.type = .customExpr
            parseExpressionScript(trimmed)
        }
    }

    private func setupExpressions(x: String, y: String, z: String) {
        do {
            self.exprX = try ExpressionEvaluator(x)
            self.exprY = try ExpressionEvaluator(y)
            self.exprZ = try ExpressionEvaluator(z)
        } catch {
            print("Expression compilation error: \(error)")
        }
    }

    private func parseExpressionScript(_ script: String) {
        // Form: expr x=2.5*cos(t); y=0.5; z=2.0*sin(t)
        var content = script
        if content.starts(with: "expr ") {
            content.removeFirst(5)
        }
        let parts = content.components(separatedBy: ";")
        var xStr = "0", yStr = "0", zStr = "0"
        for part in parts {
            let p = part.trimmingCharacters(in: .whitespaces)
            if p.lowercased().starts(with: "x=") {
                xStr = String(p.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            } else if p.lowercased().starts(with: "y=") {
                yStr = String(p.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            } else if p.lowercased().starts(with: "z=") {
                zStr = String(p.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            }
        }
        setupExpressions(x: xStr, y: yStr, z: zStr)
    }

    private func parseKeyValues(_ str: String) -> [String: Float] {
        var dict: [String: Float] = [:]
        let tokens = str.components(separatedBy: CharacterSet.whitespaces)
        for token in tokens {
            let parts = token.components(separatedBy: "=")
            if parts.count == 2 {
                let key = parts[0].lowercased()
                if let val = Float(parts[1]) {
                    dict[key] = val
                }
            }
        }
        return dict
    }

    private func parseStringValue(_ str: String, key: String) -> String? {
        let pattern = "\(key)=([^\\s]+)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)),
           let range = Range(match.range(at: 1), in: str) {
            return String(str[range])
        }
        return nil
    }

    private func parseVector(_ str: String, key: String) -> Vector3? {
        let pattern = "\(key)=\\[([^\\]]+)\\]"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)),
           let range = Range(match.range(at: 1), in: str) {
            let components = str[range].components(separatedBy: ",").compactMap { Float($0.trimmingCharacters(in: .whitespaces)) }
            if components.count >= 3 {
                return Vector3(components[0], components[1], components[2])
            }
        }
        return nil
    }

    // MARK: - Position Evaluation at Time t

    public func position(at t: Float) -> Vector3 {
        switch type {
        case .fixed:
            return fixedPosition

        case .orbit:
            let angle = t * speed * Float.pi * 2.0 + phase
            let x = radius * cos(angle)
            let z = radius * sin(angle)
            return Vector3(x, height, z)

        case .spiral:
            // Oscillate radius between min and max
            let r = minRadius + (maxRadius - minRadius) * 0.5 * (1.0 + sin(t * speed * Float.pi * 2.0))
            let angle = t * speed * 3.0 * Float.pi * 2.0
            let x = r * cos(angle)
            let z = r * sin(angle)
            let y = verticalAmplitude * sin(t * verticalSpeed * Float.pi * 2.0)
            return Vector3(x, y, z)

        case .lissajous:
            let x = xRadius * sin(t * xFreq * Float.pi * 2.0)
            let y = yRadius * sin(t * yFreq * Float.pi * 2.0 + Float.pi * 0.25)
            let z = zRadius * cos(t * zFreq * Float.pi * 2.0)
            return Vector3(x, y, z)

        case .pendulum:
            let theta = (pendulumAngleDeg * Float.pi / 180.0) * sin(t * pendulumFreq * Float.pi * 2.0)
            let displacement = pendulumLength * sin(theta)
            let verticalDrop = pendulumLength * (1.0 - cos(theta))
            if pendulumAxis.lowercased() == "x" {
                return Vector3(displacement, -verticalDrop, 1.5)
            } else {
                return Vector3(0, -verticalDrop, 1.5 + displacement)
            }

        case .wander:
            // Smooth natural Brownian-like wandering using harmonic sines
            let x = radius * (0.6 * sin(t * speed * 0.7) + 0.4 * sin(t * speed * 1.3 + 1.2))
            let y = 0.5 * radius * (0.7 * sin(t * speed * 0.4 + 2.1) + 0.3 * sin(t * speed * 1.7))
            let z = radius * (0.6 * cos(t * speed * 0.8 + 0.5) + 0.4 * cos(t * speed * 1.1 + 3.0))
            return Vector3(x, y, z)

        case .flyby:
            let cycle = flybyDuration + flybyPause
            let localT = fmod(t, cycle)
            if localT <= flybyDuration {
                let frac = localT / flybyDuration
                // Smooth ease-in-out
                let smoothFrac = frac * frac * (3.0 - 2.0 * frac)
                return Vector3.lerp(from: flybyStart, to: flybyEnd, t: smoothFrac)
            } else {
                // Keep at end during pause
                return flybyEnd
            }

        case .customExpr:
            let x = exprX?.evaluate(t: t) ?? fixedPosition.x
            let y = exprY?.evaluate(t: t) ?? fixedPosition.y
            let z = exprZ?.evaluate(t: t) ?? fixedPosition.z
            return Vector3(x, y, z)
        }
    }
}
