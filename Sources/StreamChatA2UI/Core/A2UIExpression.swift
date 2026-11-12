//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A parsed `${...}` expression from a `formatString` template.
///
/// The A2UI `formatString` function interpolates data model paths and renderer
/// side function calls into a string. This type is the parsed form of one such
/// expression, ready to be evaluated by ``ExpressionEvaluator``.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIExpression: Equatable {
    /// A data model path, absolute or relative to the current scope.
    case path(DataPath)

    /// A function call with named arguments.
    case call(name: String, arguments: [String: A2UIExpression])

    /// A literal value written inline in the template.
    case literal(any Sendable)

    /// Compares two expressions structurally.
    static func == (lhs: A2UIExpression, rhs: A2UIExpression) -> Bool {
        switch (lhs, rhs) {
        case let (.path(left), .path(right)):
            return left == right
        case let (.literal(left), .literal(right)):
            return Json.isEqual(left, right)
        case let (.call(leftName, leftArgs), .call(rightName, rightArgs)):
            guard leftName == rightName, leftArgs.keys == rightArgs.keys else { return false }
            return leftArgs.allSatisfy { key, value in rightArgs[key] == value }
        default:
            return false
        }
    }
}

/// One piece of a parsed `formatString` template.
@available(iOS 15.0, macOS 12.0, *)
enum A2UITemplateSegment: Equatable {
    /// Literal text copied verbatim into the output.
    case text(String)

    /// An expression whose evaluated value is interpolated.
    case expression(A2UIExpression)
}

/// A `formatString` template that does not parse.
@available(iOS 15.0, macOS 12.0, *)
struct A2UIExpressionError: Error, Equatable, CustomStringConvertible {
    /// What is wrong with the template.
    let message: String

    /// Creates an error with a message for the agent.
    init(_ message: String) {
        self.message = message
    }

    /// A human-readable description of the failure.
    var description: String {
        message
    }
}

/// Parses `formatString` templates and the expressions inside them.
///
/// Grammar, as defined by the A2UI v1.0 specification and its conformance suite:
///
/// * `${/absolute/path}` and `${relative/path}` interpolate the data model.
/// * `${functionName(arg: value, other: ${/path})}` calls a renderer function.
///   Arguments are named; values are quoted strings, numbers, `true`, `false`,
///   `null`, paths, calls or nested `${...}` expressions.
/// * A literal `${` is written as `\${`.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIExpressionParser {
    /// The deepest nesting of interpolations and calls an expression may use.
    static let maxNestingDepth = 100

    /// The longest template the parser accepts.
    static let maxTemplateLength = 10000

    /// The most literal and expression parts a template may have.
    static let maxTemplateParts = 1000

    /// Splits a template into literal text and expression segments.
    static func parseTemplate(_ template: String) throws -> [A2UITemplateSegment] {
        try parseTemplate(template, depth: 0)
    }

    /// Parses a single expression, without the surrounding `${}`.
    /// Returns `nil` for an empty expression.
    static func parseExpression(_ source: String) throws -> A2UIExpression? {
        try parseExpression(source, depth: 1)
    }

    // MARK: - Private

    private static func parseTemplate(_ template: String, depth: Int) throws -> [A2UITemplateSegment] {
        guard template.count <= maxTemplateLength else {
            throw A2UIExpressionError(
                "Expression template length (\(template.count)) exceeds maximum limit (\(maxTemplateLength))"
            )
        }
        var segments: [A2UITemplateSegment] = []
        var text = ""
        var scanner = Scanner(template)

        func flushText() {
            guard !text.isEmpty else { return }
            segments.append(.text(text))
            text = ""
        }

        while !scanner.isAtEnd {
            guard segments.count < maxTemplateParts else {
                throw A2UIExpressionError("Expression parts count exceeds maximum limit (\(maxTemplateParts))")
            }
            if scanner.matches("${") {
                scanner.advance(2)
                let content = try extractInterpolation(&scanner)
                if let expression = try parseExpression(content, depth: depth + 1) {
                    if case let .literal(value) = expression, let string = value as? String {
                        text += string
                    } else {
                        flushText()
                        segments.append(.expression(expression))
                    }
                }
            } else if scanner.matches("\\${") {
                scanner.advance(3)
                text += "${"
            } else {
                text.append(scanner.advance())
            }
        }
        flushText()
        return segments
    }

    private static func parseExpression(_ source: String, depth: Int) throws -> A2UIExpression? {
        guard depth <= maxNestingDepth else { throw maxDepthError }
        var scanner = Scanner(source.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !scanner.isAtEnd else { return nil }
        let expression = try parseValue(&scanner, depth: depth)
        scanner.skipWhitespace()
        guard scanner.isAtEnd else {
            throw A2UIExpressionError("Unexpected characters at end of expression: '\(scanner.rest)'")
        }
        return expression
    }

    // `null` parses as an empty string, which interpolates as nothing.
    private static func parseValue(_ scanner: inout Scanner, depth: Int) throws -> A2UIExpression? {
        guard depth <= maxNestingDepth else { throw maxDepthError }
        scanner.skipWhitespace()
        guard !scanner.isAtEnd else { return nil }

        if scanner.matches("${") {
            scanner.advance(2)
            let content = try extractInterpolation(&scanner)
            return try parseExpression(content, depth: depth + 1)
        }
        if scanner.peek() == "'" || scanner.peek() == "\"" {
            return .literal(parseString(&scanner))
        }
        if isNumberStart(scanner) {
            return .literal(try parseNumber(&scanner))
        }
        if scanner.matchKeyword("true") { return .literal(true) }
        if scanner.matchKeyword("false") { return .literal(false) }
        if scanner.matchKeyword("null") { return .literal("") }

        let token = try scanPathOrIdentifier(&scanner)
        scanner.skipWhitespace()
        if scanner.peek() == "(" {
            return try parseCall(token, &scanner, depth: depth)
        }
        if token.hasPrefix("@") {
            throw A2UIExpressionError("Expected '(' after function name '\(token)'")
        }
        return token.isEmpty ? nil : .path(DataPath(token))
    }

    private static func parseCall(_ name: String, _ scanner: inout Scanner, depth: Int) throws -> A2UIExpression {
        scanner.advance()
        scanner.skipWhitespace()
        var arguments: [String: A2UIExpression] = [:]
        while !scanner.isAtEnd, scanner.peek() != ")" {
            let argument = scanner.scan(while: isIdentifierCharacter)
            scanner.skipWhitespace()
            guard scanner.peek() == ":" else {
                throw A2UIExpressionError("Expected ':' after argument name '\(argument)' in function '\(name)'")
            }
            scanner.advance()
            arguments[argument] = try parseValue(&scanner, depth: depth + 1) ?? .literal("")
            scanner.skipWhitespace()
            if scanner.peek() == "," {
                scanner.advance()
                scanner.skipWhitespace()
            }
        }
        guard scanner.peek() == ")" else {
            throw A2UIExpressionError("Expected ')' after function arguments for '\(name)'")
        }
        scanner.advance()
        return .call(name: name, arguments: arguments)
    }

    // The content of an interpolation, from after its `${` to before its matching `}`.
    private static func extractInterpolation(_ scanner: inout Scanner) throws -> String {
        var content = ""
        var depth = 1
        while !scanner.isAtEnd {
            let character = scanner.advance()
            if character == "{" {
                depth += 1
            } else if character == "}" {
                depth -= 1
                if depth == 0 { return content }
            } else if character == "'" || character == "\"" {
                content.append(character)
                while !scanner.isAtEnd {
                    let quoted = scanner.advance()
                    content.append(quoted)
                    if quoted == "\\", !scanner.isAtEnd {
                        content.append(scanner.advance())
                    } else if quoted == character {
                        break
                    }
                }
                continue
            }
            content.append(character)
        }
        throw A2UIExpressionError("Unclosed interpolation: missing '}'")
    }

    private static func parseString(_ scanner: inout Scanner) -> String {
        let quote = scanner.advance()
        var result = ""
        while !scanner.isAtEnd {
            let character = scanner.advance()
            if character == "\\" {
                guard !scanner.isAtEnd else { break }
                switch scanner.advance() {
                case "n": result.append("\n")
                case "t": result.append("\t")
                case "r": result.append("\r")
                case let escaped: result.append(escaped)
                }
            } else if character == quote {
                break
            } else {
                result.append(character)
            }
        }
        return result
    }

    // A number starts at a digit, or a `.` before a digit, optionally signed. A `-` or `.` inside a
    // path such as `a-1` or `a.5` never gets here, because the path scanner takes the whole token.
    private static func isNumberStart(_ scanner: Scanner) -> Bool {
        let offset = scanner.peek() == "-" || scanner.peek() == "+" ? 1 : 0
        if scanner.peek(offset).isASCIIDigit { return true }
        return scanner.peek(offset) == "." && scanner.peek(offset + 1).isASCIIDigit
    }

    private static func parseNumber(_ scanner: inout Scanner) throws -> any Sendable {
        var literal = ""
        if scanner.peek() == "-" || scanner.peek() == "+" { literal.append(scanner.advance()) }
        literal += scanner.scan { $0.isASCIIDigit || $0 == "." }
        if scanner.peek() == "e" || scanner.peek() == "E" {
            literal.append(scanner.advance())
            if scanner.peek() == "+" || scanner.peek() == "-" { literal.append(scanner.advance()) }
            literal += scanner.scan { $0.isASCIIDigit }
        }
        guard isNumberLiteral(literal) else {
            throw A2UIExpressionError("Invalid number literal: '\(literal)'")
        }
        let isInteger = !literal.contains { $0 == "." || $0 == "e" || $0 == "E" }
        let unsigned = literal.hasPrefix("+") ? String(literal.dropFirst()) : literal
        if isInteger, let integer = Int(unsigned) {
            return integer
        }
        guard let number = Double(unsigned), number.isFinite else {
            throw A2UIExpressionError("Number literal is out of range: '\(literal)'")
        }
        // Adding zero turns -0 into 0.
        return number + 0
    }

    // [+-]?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][+-]?[0-9]+)?
    private static func isNumberLiteral(_ literal: String) -> Bool {
        var characters = Substring(literal)
        if characters.first == "+" || characters.first == "-" { characters = characters.dropFirst() }
        let mantissaEnd = characters.firstIndex { $0 == "e" || $0 == "E" } ?? characters.endIndex
        let mantissa = characters[..<mantissaEnd]
        let parts = mantissa.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2, parts.allSatisfy({ $0.allSatisfy(\.isASCIIDigit) }) else { return false }
        guard !(parts.first ?? "").isEmpty || (parts.count == 2 && !parts[1].isEmpty) else { return false }
        guard mantissaEnd != characters.endIndex else { return true }
        var exponent = characters[characters.index(after: mantissaEnd)...]
        if exponent.first == "+" || exponent.first == "-" { exponent = exponent.dropFirst() }
        return !exponent.isEmpty && exponent.allSatisfy(\.isASCIIDigit)
    }

    // System function names such as `@index` are ASCII: `@[A-Za-z_][A-Za-z0-9_]*`.
    private static func scanPathOrIdentifier(_ scanner: inout Scanner) throws -> String {
        if scanner.peek() == "@" {
            let first = scanner.peek(1)
            guard first.isASCII, first.isLetter || first == "_" else {
                throw A2UIExpressionError("Invalid identifier starting with '@' in expression")
            }
            scanner.advance()
            return "@" + scanner.scan { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }
        }
        return scanner.scan { isIdentifierCharacter($0) || $0 == "/" || $0 == "." || $0 == "-" }
    }

    private static func isIdentifierCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy(\.properties.isXIDContinue)
    }

    private static var maxDepthError: A2UIExpressionError {
        A2UIExpressionError("Max recursion depth reached in parse")
    }

    private struct Scanner {
        private let characters: [Character]
        private var position = 0

        init(_ source: String) {
            characters = Array(source)
        }

        var isAtEnd: Bool {
            position >= characters.count
        }

        var rest: String {
            String(characters[min(position, characters.count)...])
        }

        func peek(_ offset: Int = 0) -> Character {
            position + offset < characters.count ? characters[position + offset] : "\0"
        }

        func matches(_ expected: String) -> Bool {
            var offset = 0
            for character in expected {
                guard peek(offset) == character else { return false }
                offset += 1
            }
            return true
        }

        @discardableResult
        mutating func advance() -> Character {
            let character = peek()
            position += 1
            return character
        }

        mutating func advance(_ count: Int) {
            position += count
        }

        mutating func scan(while predicate: (Character) -> Bool) -> String {
            var result = ""
            while !isAtEnd, predicate(peek()) {
                result.append(advance())
            }
            return result
        }

        mutating func skipWhitespace() {
            _ = scan { $0.isWhitespace }
        }

        // A keyword must not run on into an identifier: `trueish` is a path.
        mutating func matchKeyword(_ keyword: String) -> Bool {
            guard matches(keyword) else { return false }
            let next = peek(keyword.count)
            guard next == "\0" || !A2UIExpressionParser.isIdentifierCharacter(next) else { return false }
            advance(keyword.count)
            return true
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
private extension Character {
    var isASCIIDigit: Bool {
        isASCII && isNumber
    }
}
