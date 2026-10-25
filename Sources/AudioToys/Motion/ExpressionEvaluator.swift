import Foundation

/// Fast recursive descent parser and evaluator for mathematical expressions f(t).
/// Supports variables: 't' (time in seconds)
/// Constants: pi, e
/// Functions: sin, cos, tan, abs, sqrt, noise, clamp, min, max
/// Operators: +, -, *, /, ^ (power), parentheses
public final class ExpressionEvaluator: @unchecked Sendable {
    public enum EvalError: Error, CustomStringConvertible {
        case unexpectedToken(String)
        case unexpectedEnd
        case invalidSyntax(String)

        public var description: String {
            switch self {
            case .unexpectedToken(let str): return "Unexpected token: \(str)"
            case .unexpectedEnd: return "Unexpected end of expression"
            case .invalidSyntax(let str): return "Invalid syntax: \(str)"
            }
        }
    }

    private indirect enum Node {
        case number(Float)
        case variableT
        case unaryOp(Character, Node)
        case binaryOp(Character, Node, Node)
        case functionCall(String, [Node])
    }

    private let parsedNode: Node

    public init(_ expression: String) throws {
        var tokens = try ExpressionEvaluator.tokenize(expression)
        let node = try ExpressionEvaluator.parseExpression(&tokens)
        if !tokens.isEmpty {
            throw EvalError.unexpectedToken(tokens.first?.text ?? "")
        }
        self.parsedNode = node
    }

    public func evaluate(t: Float) -> Float {
        return evaluateNode(parsedNode, t: t)
    }

    private func evaluateNode(_ node: Node, t: Float) -> Float {
        switch node {
        case .number(let val):
            return val
        case .variableT:
            return t
        case .unaryOp(let op, let child):
            let val = evaluateNode(child, t: t)
            return op == "-" ? -val : val
        case .binaryOp(let op, let left, let right):
            let lVal = evaluateNode(left, t: t)
            let rVal = evaluateNode(right, t: t)
            switch op {
            case "+": return lVal + rVal
            case "-": return lVal - rVal
            case "*": return lVal * rVal
            case "/": return rVal != 0 ? lVal / rVal : 0
            case "^": return pow(lVal, rVal)
            default: return 0
            }
        case .functionCall(let fn, let args):
            let evaluatedArgs = args.map { evaluateNode($0, t: t) }
            switch fn.lowercased() {
            case "sin": return sin(evaluatedArgs.first ?? 0)
            case "cos": return cos(evaluatedArgs.first ?? 0)
            case "tan": return tan(evaluatedArgs.first ?? 0)
            case "abs": return abs(evaluatedArgs.first ?? 0)
            case "sqrt":
                let v = evaluatedArgs.first ?? 0
                return v >= 0 ? sqrt(v) : 0
            case "noise":
                let v = evaluatedArgs.first ?? 0
                return ExpressionEvaluator.pseudoNoise(v)
            case "min":
                return min(evaluatedArgs.first ?? 0, evaluatedArgs.count > 1 ? evaluatedArgs[1] : 0)
            case "max":
                return max(evaluatedArgs.first ?? 0, evaluatedArgs.count > 1 ? evaluatedArgs[1] : 0)
            case "clamp":
                guard evaluatedArgs.count >= 3 else { return evaluatedArgs.first ?? 0 }
                return min(max(evaluatedArgs[0], evaluatedArgs[1]), evaluatedArgs[2])
            default:
                return 0
            }
        }
    }

    // Pseudo-noise for procedural natural wandering
    private static func pseudoNoise(_ x: Float) -> Float {
        let i = floor(x)
        let f = x - i
        let u = f * f * (3.0 - 2.0 * f) // smoothstep
        let n0 = fract(sin(i * 12.9898) * 43758.5453) * 2.0 - 1.0
        let n1 = fract(sin((i + 1.0) * 12.9898) * 43758.5453) * 2.0 - 1.0
        return n0 * (1.0 - u) + n1 * u
    }

    private static func fract(_ x: Float) -> Float {
        x - floor(x)
    }

    // Tokenizer
    private struct Token {
        enum Kind { case number, identifier, symbol }
        let kind: Kind
        let text: String
    }

    private static func tokenize(_ str: String) throws -> [Token] {
        var tokens: [Token] = []
        let chars = Array(str)
        var i = 0

        while i < chars.count {
            let c = chars[i]
            if c.isWhitespace {
                i += 1
                continue
            }
            if c.isNumber || c == "." {
                var numStr = ""
                while i < chars.count && (chars[i].isNumber || chars[i] == ".") {
                    numStr.append(chars[i])
                    i += 1
                }
                tokens.append(Token(kind: .number, text: numStr))
                continue
            }
            if c.isLetter {
                var identStr = ""
                while i < chars.count && (chars[i].isLetter || chars[i].isNumber || chars[i] == "_") {
                    identStr.append(chars[i])
                    i += 1
                }
                tokens.append(Token(kind: .identifier, text: identStr))
                continue
            }
            if "+-*/^(),".contains(c) {
                tokens.append(Token(kind: .symbol, text: String(c)))
                i += 1
                continue
            }
            throw EvalError.unexpectedToken(String(c))
        }
        return tokens
    }

    // Parser
    private static func parseExpression(_ tokens: inout [Token]) throws -> Node {
        return try parseBinaryOp(&tokens, minPrec: 0)
    }

    private static func precedence(for op: Character) -> Int {
        switch op {
        case "+", "-": return 1
        case "*", "/": return 2
        case "^": return 3
        default: return 0
        }
    }

    private static func parseBinaryOp(_ tokens: inout [Token], minPrec: Int) throws -> Node {
        var left = try parsePrimary(&tokens)

        while !tokens.isEmpty {
            guard let opChar = tokens.first?.text.first, "+-*/^".contains(opChar) else {
                break
            }
            let prec = precedence(for: opChar)
            if prec < minPrec {
                break
            }
            tokens.removeFirst()
            let nextMinPrec = (opChar == "^") ? prec : prec + 1
            let right = try parseBinaryOp(&tokens, minPrec: nextMinPrec)
            left = .binaryOp(opChar, left, right)
        }
        return left
    }

    private static func parsePrimary(_ tokens: inout [Token]) throws -> Node {
        guard !tokens.isEmpty else { throw EvalError.unexpectedEnd }
        let token = tokens.removeFirst()

        if token.kind == .symbol && token.text == "-" {
            let child = try parsePrimary(&tokens)
            return .unaryOp("-", child)
        }

        if token.kind == .symbol && token.text == "(" {
            let expr = try parseExpression(&tokens)
            guard !tokens.isEmpty, tokens.first?.text == ")" else {
                throw EvalError.invalidSyntax("Missing closing parenthesis")
            }
            tokens.removeFirst() // consume ')'
            return expr
        }

        if token.kind == .number {
            guard let val = Float(token.text) else {
                throw EvalError.invalidSyntax("Invalid number: \(token.text)")
            }
            return .number(val)
        }

        if token.kind == .identifier {
            let lower = token.text.lowercased()
            if lower == "t" {
                return .variableT
            }
            if lower == "pi" {
                return .number(Float.pi)
            }
            if lower == "e" {
                return .number(Float(M_E))
            }
            // Check for function call
            if !tokens.isEmpty && tokens.first?.text == "(" {
                tokens.removeFirst() // consume '('
                var args: [Node] = []
                if !tokens.isEmpty && tokens.first?.text != ")" {
                    args.append(try parseExpression(&tokens))
                    while !tokens.isEmpty && tokens.first?.text == "," {
                        tokens.removeFirst()
                        args.append(try parseExpression(&tokens))
                    }
                }
                guard !tokens.isEmpty, tokens.first?.text == ")" else {
                    throw EvalError.invalidSyntax("Missing closing parenthesis in function \(token.text)")
                }
                tokens.removeFirst()
                return .functionCall(token.text, args)
            }
            throw EvalError.invalidSyntax("Unknown identifier: \(token.text)")
        }

        throw EvalError.unexpectedToken(token.text)
    }
}
