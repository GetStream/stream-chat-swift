//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Token kinds (mirrors the `T` const enum in `tokens.ts`).
@available(iOS 17.0, macOS 14.0, *)
enum TokenKind: UInt8, Sendable {
    case newline
    case lParen, rParen, lBrack, rBrack, lBrace, rBrace
    case comma, colon, equals
    case `true`, `false`, null
    case eof
    case str, num
    /// Lowercase identifier — a reference.
    case ident
    /// PascalCase identifier — a component name or reference.
    case type
    /// `$identifier`
    case stateVar
    case dot, plus, minus, star, slash, percent
    case eqEq, notEq, greater, less, greaterEq, lessEq
    case and, or, not, question
    /// `@identifier`
    case builtinCall
}

@available(iOS 17.0, macOS 14.0, *)
struct Token: Sendable, Equatable {
    var kind: TokenKind
    var text: String?
    var number: Double?

    init(_ kind: TokenKind, text: String? = nil, number: Double? = nil) {
        self.kind = kind
        self.text = text
        self.number = number
    }

    static let eof = Token(.eof)

    /// `String(token.v)` in the reference implementation.
    var stringValue: String {
        if let text { return text }
        if let number { return JS.numberToString(number) }
        return "undefined"
    }
}

/// Tokenizes OpenUI Lang source (port of `tokenize` in `lexer.ts`).
@available(iOS 17.0, macOS 14.0, *)
enum Lexer {
    static func tokenize(_ source: String) -> [Token] {
        tokenize(Array(source.utf8))
    }

    static func tokenize(_ src: [UInt8]) -> [Token] {
        var tokens: [Token] = []
        tokens.reserveCapacity(src.count / 3)
        var i = 0
        let n = src.count

        @inline(__always) func at(_ index: Int) -> UInt8 { index < n ? src[index] : 0 }

        while i < n {
            while i < n, src[i] == 0x20 || src[i] == 0x09 || src[i] == 0x0d { i += 1 }
            if i >= n { break }

            let c = src[i]
            switch c {
            case 0x0a:
                tokens.append(Token(.newline)); i += 1; continue
            case UInt8(ascii: "("):
                tokens.append(Token(.lParen)); i += 1; continue
            case UInt8(ascii: ")"):
                tokens.append(Token(.rParen)); i += 1; continue
            case UInt8(ascii: "["):
                tokens.append(Token(.lBrack)); i += 1; continue
            case UInt8(ascii: "]"):
                tokens.append(Token(.rBrack)); i += 1; continue
            case UInt8(ascii: "{"):
                tokens.append(Token(.lBrace)); i += 1; continue
            case UInt8(ascii: "}"):
                tokens.append(Token(.rBrace)); i += 1; continue
            case UInt8(ascii: ","):
                tokens.append(Token(.comma)); i += 1; continue
            case UInt8(ascii: ":"):
                tokens.append(Token(.colon)); i += 1; continue
            case UInt8(ascii: "="):
                if at(i + 1) == UInt8(ascii: "=") {
                    tokens.append(Token(.eqEq)); i += 2
                } else {
                    tokens.append(Token(.equals)); i += 1
                }
                continue
            case UInt8(ascii: "!"):
                if at(i + 1) == UInt8(ascii: "=") {
                    tokens.append(Token(.notEq)); i += 2
                } else {
                    tokens.append(Token(.not)); i += 1
                }
                continue
            case UInt8(ascii: ">"):
                if at(i + 1) == UInt8(ascii: "=") {
                    tokens.append(Token(.greaterEq)); i += 2
                } else {
                    tokens.append(Token(.greater)); i += 1
                }
                continue
            case UInt8(ascii: "<"):
                if at(i + 1) == UInt8(ascii: "=") {
                    tokens.append(Token(.lessEq)); i += 2
                } else {
                    tokens.append(Token(.less)); i += 1
                }
                continue
            case UInt8(ascii: "&"):
                tokens.append(Token(.and)); i += at(i + 1) == UInt8(ascii: "&") ? 2 : 1; continue
            case UInt8(ascii: "|"):
                tokens.append(Token(.or)); i += at(i + 1) == UInt8(ascii: "|") ? 2 : 1; continue
            case UInt8(ascii: "."):
                tokens.append(Token(.dot)); i += 1; continue
            case UInt8(ascii: "?"):
                tokens.append(Token(.question)); i += 1; continue
            case UInt8(ascii: "+"):
                tokens.append(Token(.plus)); i += 1; continue
            case UInt8(ascii: "*"):
                tokens.append(Token(.star)); i += 1; continue
            case UInt8(ascii: "/"):
                tokens.append(Token(.slash)); i += 1; continue
            case UInt8(ascii: "%"):
                tokens.append(Token(.percent)); i += 1; continue
            case UInt8(ascii: "\""):
                let start = i
                i += 1
                var isClosed = false
                while i < n {
                    if src[i] == UInt8(ascii: "\\") {
                        i += 2
                    } else if src[i] == UInt8(ascii: "\"") {
                        i += 1
                        isClosed = true
                        break
                    } else {
                        i += 1
                    }
                }
                let end = Swift.min(i, n)
                var raw = Array(src[start..<end])
                if !isClosed { raw.append(UInt8(ascii: "\"")) }
                if let decoded = OpenUIJSON.decodeStringLiteral(raw[...]) {
                    tokens.append(Token(.str, text: decoded))
                } else {
                    // Malformed literal (e.g. raw newlines or a half-streamed escape): keep raw text.
                    var stripped = Array(src[start..<end])
                    if stripped.first == UInt8(ascii: "\"") { stripped.removeFirst() }
                    if stripped.last == UInt8(ascii: "\"") { stripped.removeLast() }
                    tokens.append(Token(.str, text: String(decoding: stripped, as: UTF8.self)))
                }
                continue
            case UInt8(ascii: "'"):
                i += 1
                var result: [UInt8] = []
                while i < n {
                    if src[i] == UInt8(ascii: "\\") {
                        i += 1
                        if i < n {
                            switch src[i] {
                            case UInt8(ascii: "'"): result.append(UInt8(ascii: "'"))
                            case UInt8(ascii: "\\"): result.append(UInt8(ascii: "\\"))
                            case UInt8(ascii: "n"): result.append(0x0a)
                            case UInt8(ascii: "t"): result.append(0x09)
                            default: result.append(src[i])
                            }
                            i += 1
                        }
                    } else if src[i] == UInt8(ascii: "'") {
                        i += 1
                        break
                    } else {
                        result.append(src[i])
                        i += 1
                    }
                }
                tokens.append(Token(.str, text: String(decoding: result, as: UTF8.self)))
                continue
            default:
                break
            }

            if c == UInt8(ascii: "-") {
                let afterValue: Bool
                if let previous = tokens.last {
                    switch previous.kind {
                    case .num, .str, .ident, .type, .rParen, .rBrack, .true, .false, .null, .stateVar, .builtinCall:
                        afterValue = true
                    default:
                        afterValue = false
                    }
                } else {
                    afterValue = false
                }
                if afterValue || !isDigit(at(i + 1)) {
                    tokens.append(Token(.minus))
                    i += 1
                    continue
                }
            }

            if isDigit(c) || (c == UInt8(ascii: "-") && isDigit(at(i + 1))) {
                let start = i
                if src[i] == UInt8(ascii: "-") { i += 1 }
                while i < n, isDigit(src[i]) { i += 1 }
                if i < n, src[i] == UInt8(ascii: "."), isDigit(at(i + 1)) {
                    i += 1
                    while i < n, isDigit(src[i]) { i += 1 }
                }
                if i < n, src[i] == UInt8(ascii: "e") || src[i] == UInt8(ascii: "E") {
                    i += 1
                    if i < n, src[i] == UInt8(ascii: "+") || src[i] == UInt8(ascii: "-") { i += 1 }
                    while i < n, isDigit(src[i]) { i += 1 }
                }
                let lexeme = String(decoding: src[start..<i], as: UTF8.self)
                tokens.append(Token(.num, number: JS.stringToNumber(lexeme)))
                continue
            }

            if c == UInt8(ascii: "$"), isIdentifierStart(at(i + 1)) {
                let start = i
                i += 1
                while i < n, isIdentifierPart(src[i]) { i += 1 }
                tokens.append(Token(.stateVar, text: String(decoding: src[start..<i], as: UTF8.self)))
                continue
            }

            if isIdentifierStart(c) {
                let start = i
                while i < n, isIdentifierPart(src[i]) { i += 1 }
                let word = String(decoding: src[start..<i], as: UTF8.self)
                switch word {
                case "true": tokens.append(Token(.true))
                case "false": tokens.append(Token(.false))
                case "null": tokens.append(Token(.null))
                default:
                    let isUppercase = c >= UInt8(ascii: "A") && c <= UInt8(ascii: "Z")
                    tokens.append(Token(isUppercase ? .type : .ident, text: word))
                }
                continue
            }

            if c == UInt8(ascii: "@"), isIdentifierStart(at(i + 1)) {
                i += 1
                let start = i
                while i < n, isIdentifierPart(src[i]) { i += 1 }
                tokens.append(Token(.builtinCall, text: String(decoding: src[start..<i], as: UTF8.self)))
                continue
            }

            // Skip any other character (e.g. `#`, emoji bytes).
            i += 1
        }

        tokens.append(.eof)
        return tokens
    }

    @inline(__always) private static func isDigit(_ byte: UInt8) -> Bool {
        byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9")
    }

    @inline(__always) private static func isIdentifierStart(_ byte: UInt8) -> Bool {
        (byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "z"))
            || (byte >= UInt8(ascii: "A") && byte <= UInt8(ascii: "Z"))
            || byte == UInt8(ascii: "_")
    }

    @inline(__always) private static func isIdentifierPart(_ byte: UInt8) -> Bool {
        isIdentifierStart(byte) || isDigit(byte)
    }
}
