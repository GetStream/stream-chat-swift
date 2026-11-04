//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A raw `identifier = expression` statement before expression parsing.
@available(iOS 17.0, macOS 14.0, *)
struct RawStatement: Sendable {
    var id: String
    /// Token kind of the left-hand identifier (used to classify `$state` declarations).
    var idKind: TokenKind
    var tokens: [Token]
}

/// Statement-level helpers (port of `statements.ts`).
@available(iOS 17.0, macOS 14.0, *)
enum Statements {
    /// Auto-closes unclosed strings and brackets so partial (streaming) input parses.
    static func autoClose(_ input: String) -> (text: String, wasIncomplete: Bool) {
        var stack: [UInt8] = []
        var inString: UInt8?
        var escaped = false

        for byte in input.utf8 {
            if escaped {
                escaped = false
                continue
            }
            if byte == UInt8(ascii: "\\"), inString != nil {
                escaped = true
                continue
            }
            if let quote = inString {
                if byte == quote { inString = nil }
                continue
            }
            switch byte {
            case UInt8(ascii: "\""), UInt8(ascii: "'"):
                inString = byte
            case UInt8(ascii: "("), UInt8(ascii: "["), UInt8(ascii: "{"):
                stack.append(byte)
            case UInt8(ascii: ")"):
                if stack.last == UInt8(ascii: "(") { stack.removeLast() }
            case UInt8(ascii: "]"):
                if stack.last == UInt8(ascii: "[") { stack.removeLast() }
            case UInt8(ascii: "}"):
                if stack.last == UInt8(ascii: "{") { stack.removeLast() }
            default:
                break
            }
        }

        let wasIncomplete = inString != nil || !stack.isEmpty
        guard wasIncomplete else { return (input, false) }

        var output = input
        if let quote = inString {
            if escaped { output += "\\" }
            output.unicodeScalars.append(Unicode.Scalar(quote))
        }
        for opener in stack.reversed() {
            switch opener {
            case UInt8(ascii: "("): output += ")"
            case UInt8(ascii: "["): output += "]"
            default: output += "}"
            }
        }
        return (output, true)
    }

    /// Splits a token stream into statements. Statements are separated by newlines at bracket depth 0;
    /// multiline ternaries (`cond\n ? a\n : b`) are kept together. Invalid lines are skipped.
    static func split(_ tokens: [Token]) -> [RawStatement] {
        var statements: [RawStatement] = []
        var position = 0
        let count = tokens.count

        while position < count {
            while position < count, tokens[position].kind == .newline { position += 1 }
            if position >= count || tokens[position].kind == .eof { break }

            let token = tokens[position]
            guard token.kind == .ident || token.kind == .type || token.kind == .stateVar else {
                while position < count, tokens[position].kind != .newline, tokens[position].kind != .eof { position += 1 }
                continue
            }
            let id = token.text ?? ""
            let idKind = token.kind
            position += 1

            guard position < count, tokens[position].kind == .equals else {
                while position < count, tokens[position].kind != .newline, tokens[position].kind != .eof { position += 1 }
                continue
            }
            position += 1

            var expression: [Token] = []
            var depth = 0
            var ternaryDepth = 0
            while position < count, tokens[position].kind != .eof {
                let kind = tokens[position].kind
                if kind == .newline, depth <= 0, ternaryDepth <= 0 {
                    // A `?` on a following line continues a multiline ternary.
                    var peek = position + 1
                    while peek < count, tokens[peek].kind == .newline { peek += 1 }
                    let next = peek < count ? tokens[peek].kind : .eof
                    if next == .question || (next == .colon && ternaryDepth > 0) {
                        position += 1
                        continue
                    }
                    break
                }
                if kind == .newline {
                    position += 1
                    continue
                }
                switch kind {
                case .lParen, .lBrack, .lBrace:
                    depth += 1
                case .rParen, .rBrack, .rBrace:
                    if depth > 0 { depth -= 1 }
                case .question:
                    if depth == 0 { ternaryDepth += 1 }
                case .colon:
                    if depth == 0 && ternaryDepth > 0 { ternaryDepth -= 1 }
                default:
                    break
                }
                expression.append(tokens[position])
                position += 1
            }

            if !expression.isEmpty {
                statements.append(RawStatement(id: id, idKind: idKind, tokens: expression))
            }
        }
        return statements
    }
}

/// Source cleanup applied before parsing: markdown fences and line comments (port of `parser.ts`).
@available(iOS 17.0, macOS 14.0, *)
enum Preprocessor {
    /// `stripComments(stripFences(input.trim())).trim()`
    static func preprocess(_ input: String) -> String {
        JS.trim(stripComments(stripFences(JS.trim(input))))
    }

    /// Index just past a double-quoted string starting at `start`, or `start` if there is none.
    private static func skipString(_ bytes: [UInt8], _ start: Int) -> Int {
        guard start < bytes.count, bytes[start] == UInt8(ascii: "\"") else { return start }
        var i = start + 1
        while i < bytes.count {
            if bytes[i] == UInt8(ascii: "\\") {
                i += 2
            } else if bytes[i] == UInt8(ascii: "\"") {
                return i + 1
            } else {
                i += 1
            }
        }
        return i
    }

    private static func isFence(_ bytes: [UInt8], _ i: Int) -> Bool {
        i + 2 < bytes.count
            && bytes[i] == UInt8(ascii: "`")
            && bytes[i + 1] == UInt8(ascii: "`")
            && bytes[i + 2] == UInt8(ascii: "`")
    }

    /// Extracts code from markdown fences, or returns the input unchanged when there are none.
    /// Fences inside double-quoted strings are ignored.
    static func stripFences(_ input: String) -> String {
        let bytes = Array(input.utf8)
        let n = bytes.count
        var blocks: [String] = []
        var i = 0

        func text(_ start: Int, _ end: Int) -> String {
            let lower = Swift.min(start, n)
            let upper = Swift.min(Swift.max(end, lower), n)
            return String(decoding: bytes[lower..<upper], as: UTF8.self)
        }

        while i < n {
            var fenceStart = -1
            while i < n {
                let next = skipString(bytes, i)
                if next > i {
                    i = next
                    continue
                }
                if isFence(bytes, i) {
                    fenceStart = i
                    break
                }
                i += 1
            }
            if fenceStart == -1 { break }

            var j = fenceStart + 3
            while j < n, bytes[j] != 0x0a { j += 1 }
            if j >= n {
                // No newline after the opening fence (streaming): drop the language tag line.
                var rest = Array(bytes[(fenceStart + 3)...])
                if let newline = rest.firstIndex(of: 0x0a) {
                    rest.removeSubrange(0...newline)
                } else {
                    rest.removeAll()
                }
                blocks.append(String(decoding: rest, as: UTF8.self))
                i = n
                break
            }
            j += 1

            var closePosition = -1
            var k = j
            while k < n {
                let next = skipString(bytes, k)
                if next > k {
                    k = next
                    continue
                }
                if isFence(bytes, k) {
                    closePosition = k
                    break
                }
                k += 1
            }

            if closePosition != -1 {
                blocks.append(text(j, closePosition))
                i = closePosition + 3
            } else {
                blocks.append(text(j, n))
                i = n
            }
        }

        if !blocks.isEmpty { return blocks.joined(separator: "\n") }

        if input.hasPrefix("```") {
            var j = 3
            while j < n, bytes[j] != 0x0a { j += 1 }
            let start = j < n ? j + 1 : 3
            let body = Array(bytes[Swift.min(start, n)...])
            if let trailing = lastFenceIndex(body) {
                return String(decoding: body[..<trailing], as: UTF8.self)
            }
            return String(decoding: body, as: UTF8.self)
        }
        return input
    }

    private static func lastFenceIndex(_ bytes: [UInt8]) -> Int? {
        guard bytes.count >= 3 else { return nil }
        var i = bytes.count - 3
        while i >= 0 {
            if bytes[i] == UInt8(ascii: "`"), bytes[i + 1] == UInt8(ascii: "`"), bytes[i + 2] == UInt8(ascii: "`") {
                return i
            }
            i -= 1
        }
        return nil
    }

    /// Strips `//` and `#` line comments outside of strings. String state carries across lines.
    static func stripComments(_ input: String) -> String {
        var inString: UInt8?
        // Split on the line feed code unit, as JavaScript does: Swift reads "\r\n" as one Character.
        let lines = input.components(separatedBy: "\n")
        var output: [String] = []
        output.reserveCapacity(lines.count)

        for line in lines {
            let bytes = Array(line.utf8)
            var cut: Int?
            var i = 0
            while i < bytes.count {
                let c = bytes[i]
                if let quote = inString {
                    if c == UInt8(ascii: "\\"), i + 1 < bytes.count {
                        i += 2
                        continue
                    }
                    if c == quote { inString = nil }
                    i += 1
                    continue
                }
                if c == UInt8(ascii: "\"") || c == UInt8(ascii: "'") {
                    inString = c
                    i += 1
                    continue
                }
                if c == UInt8(ascii: "/"), i + 1 < bytes.count, bytes[i + 1] == UInt8(ascii: "/") {
                    cut = i
                    break
                }
                if c == UInt8(ascii: "#") {
                    cut = i
                    break
                }
                i += 1
            }
            if let cut {
                output.append(JS.trimEnd(String(decoding: bytes[..<cut], as: UTF8.self)))
            } else {
                output.append(line)
            }
        }
        return output.joined(separator: "\n")
    }
}
