//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Errors thrown by ``OpenUIJSON``.
@available(iOS 17.0, macOS 14.0, *)
struct OpenUIJSONError: Error, Sendable, Equatable, CustomStringConvertible {
    let message: String
    let offset: Int

    var description: String { "\(message) at offset \(offset)" }
}

/// A strict JSON parser with `JSON.parse` semantics that preserves object key order.
///
/// Key order is part of the OpenUI contract (component props are positional and follow the order
/// of the schema's `properties`), so Foundation's `JSONSerialization` is not suitable.
@available(iOS 17.0, macOS 14.0, *)
enum OpenUIJSON {
    /// Parses JSON text into an ``OpenUIValue``.
    static func parse(_ text: String) throws -> OpenUIValue {
        try parse(Array(text.utf8))
    }

    /// Parses UTF-8 encoded JSON data into an ``OpenUIValue``.
    static func parse(_ data: Data) throws -> OpenUIValue {
        try parse([UInt8](data))
    }

    static func parse(_ bytes: [UInt8]) throws -> OpenUIValue {
        var reader = Reader(bytes: bytes)
        reader.skipWhitespace()
        let value = try reader.parseValue(depth: 0)
        reader.skipWhitespace()
        guard reader.isAtEnd else { throw reader.error("Unexpected trailing content") }
        return value
    }

    /// Decodes a complete JSON string literal (including its quotes), or returns `nil` when the
    /// literal is not valid JSON — mirroring `JSON.parse` on a quoted string.
    static func decodeStringLiteral(_ bytes: ArraySlice<UInt8>) -> String? {
        var reader = Reader(bytes: Array(bytes))
        guard let value = try? reader.parseString(), reader.isAtEnd else { return nil }
        return value
    }

    /// Serializes a value as compact JSON (`JSON.stringify` semantics).
    static func stringify(_ value: OpenUIValue) -> String {
        JS.jsonStringify(value) ?? "null"
    }

    private struct Reader {
        let bytes: [UInt8]
        var index = 0

        var isAtEnd: Bool { index >= bytes.count }

        func error(_ message: String) -> OpenUIJSONError {
            OpenUIJSONError(message: message, offset: index)
        }

        mutating func skipWhitespace() {
            while index < bytes.count {
                switch bytes[index] {
                case 0x20, 0x09, 0x0a, 0x0d: index += 1
                default: return
                }
            }
        }

        mutating func parseValue(depth: Int) throws -> OpenUIValue {
            guard depth < 512 else { throw error("Nesting too deep") }
            guard index < bytes.count else { throw error("Unexpected end of input") }
            switch bytes[index] {
            case UInt8(ascii: "{"): return try parseObject(depth: depth)
            case UInt8(ascii: "["): return try parseArray(depth: depth)
            case UInt8(ascii: "\""): return .string(try parseString())
            case UInt8(ascii: "t"): try expectLiteral("true"); return .bool(true)
            case UInt8(ascii: "f"): try expectLiteral("false"); return .bool(false)
            case UInt8(ascii: "n"): try expectLiteral("null"); return .null
            default: return .number(try parseNumber())
            }
        }

        mutating func expectLiteral(_ literal: StaticString) throws {
            let count = literal.utf8CodeUnitCount
            guard index + count <= bytes.count else { throw error("Unexpected end of input") }
            let expected = UnsafeBufferPointer(start: literal.utf8Start, count: count)
            for offset in 0..<count where bytes[index + offset] != expected[offset] {
                throw error("Unexpected token")
            }
            index += count
        }

        mutating func parseObject(depth: Int) throws -> OpenUIValue {
            index += 1
            var object = OpenUIObject()
            skipWhitespace()
            if index < bytes.count, bytes[index] == UInt8(ascii: "}") {
                index += 1
                return .object(object)
            }
            while true {
                skipWhitespace()
                guard index < bytes.count, bytes[index] == UInt8(ascii: "\"") else {
                    throw error("Expected property name")
                }
                let key = try parseString()
                skipWhitespace()
                guard index < bytes.count, bytes[index] == UInt8(ascii: ":") else { throw error("Expected ':'") }
                index += 1
                skipWhitespace()
                object[key] = try parseValue(depth: depth + 1)
                skipWhitespace()
                guard index < bytes.count else { throw error("Unexpected end of input") }
                if bytes[index] == UInt8(ascii: ",") {
                    index += 1
                    continue
                }
                if bytes[index] == UInt8(ascii: "}") {
                    index += 1
                    return .object(object)
                }
                throw error("Expected ',' or '}'")
            }
        }

        mutating func parseArray(depth: Int) throws -> OpenUIValue {
            index += 1
            var items: [OpenUIValue] = []
            skipWhitespace()
            if index < bytes.count, bytes[index] == UInt8(ascii: "]") {
                index += 1
                return .array(items)
            }
            while true {
                skipWhitespace()
                items.append(try parseValue(depth: depth + 1))
                skipWhitespace()
                guard index < bytes.count else { throw error("Unexpected end of input") }
                if bytes[index] == UInt8(ascii: ",") {
                    index += 1
                    continue
                }
                if bytes[index] == UInt8(ascii: "]") {
                    index += 1
                    return .array(items)
                }
                throw error("Expected ',' or ']'")
            }
        }

        mutating func parseString() throws -> String {
            guard index < bytes.count, bytes[index] == UInt8(ascii: "\"") else { throw error("Expected string") }
            index += 1
            var scalars = String.UnicodeScalarView()
            var runStart = index
            func flushRun(upTo end: Int, into scalars: inout String.UnicodeScalarView) {
                if end > runStart {
                    scalars.append(contentsOf: String(decoding: bytes[runStart..<end], as: UTF8.self).unicodeScalars)
                }
            }
            while index < bytes.count {
                let byte = bytes[index]
                if byte == UInt8(ascii: "\"") {
                    flushRun(upTo: index, into: &scalars)
                    index += 1
                    return String(scalars)
                }
                if byte < 0x20 {
                    throw error("Bad control character in string literal")
                }
                if byte == UInt8(ascii: "\\") {
                    flushRun(upTo: index, into: &scalars)
                    index += 1
                    guard index < bytes.count else { throw error("Unterminated string") }
                    let escape = bytes[index]
                    index += 1
                    switch escape {
                    case UInt8(ascii: "\""): scalars.append("\"")
                    case UInt8(ascii: "\\"): scalars.append("\\")
                    case UInt8(ascii: "/"): scalars.append("/")
                    case UInt8(ascii: "b"): scalars.append("\u{08}")
                    case UInt8(ascii: "f"): scalars.append("\u{0C}")
                    case UInt8(ascii: "n"): scalars.append("\n")
                    case UInt8(ascii: "r"): scalars.append("\r")
                    case UInt8(ascii: "t"): scalars.append("\t")
                    case UInt8(ascii: "u"):
                        let unit = try parseHex4()
                        if (0xd800...0xdbff).contains(unit),
                           index + 6 <= bytes.count,
                           bytes[index] == UInt8(ascii: "\\"),
                           bytes[index + 1] == UInt8(ascii: "u") {
                            let saved = index
                            index += 2
                            let low = try parseHex4()
                            if (0xdc00...0xdfff).contains(low) {
                                let value = 0x10000 + ((UInt32(unit) - 0xd800) << 10) + (UInt32(low) - 0xdc00)
                                scalars.append(Unicode.Scalar(value) ?? "\u{FFFD}")
                            } else {
                                // Lone high surrogate followed by another escape.
                                scalars.append("\u{FFFD}")
                                index = saved
                            }
                        } else {
                            scalars.append(Unicode.Scalar(UInt32(unit)) ?? "\u{FFFD}")
                        }
                    default:
                        throw error("Bad escaped character")
                    }
                    runStart = index
                    continue
                }
                index += 1
            }
            throw error("Unterminated string")
        }

        mutating func parseHex4() throws -> UInt16 {
            guard index + 4 <= bytes.count else { throw error("Bad Unicode escape") }
            var value: UInt16 = 0
            for _ in 0..<4 {
                let byte = bytes[index]
                let digit: UInt16
                switch byte {
                case UInt8(ascii: "0")...UInt8(ascii: "9"): digit = UInt16(byte - UInt8(ascii: "0"))
                case UInt8(ascii: "a")...UInt8(ascii: "f"): digit = UInt16(byte - UInt8(ascii: "a") + 10)
                case UInt8(ascii: "A")...UInt8(ascii: "F"): digit = UInt16(byte - UInt8(ascii: "A") + 10)
                default: throw error("Bad Unicode escape")
                }
                value = value * 16 + digit
                index += 1
            }
            return value
        }

        mutating func parseNumber() throws -> Double {
            let start = index
            if index < bytes.count, bytes[index] == UInt8(ascii: "-") { index += 1 }
            guard index < bytes.count else { throw error("Unexpected end of input") }
            if bytes[index] == UInt8(ascii: "0") {
                index += 1
            } else if isDigit(bytes[index]) {
                while index < bytes.count, isDigit(bytes[index]) { index += 1 }
            } else {
                throw error("Unexpected token")
            }
            if index < bytes.count, bytes[index] == UInt8(ascii: ".") {
                index += 1
                guard index < bytes.count, isDigit(bytes[index]) else { throw error("Unterminated fractional number") }
                while index < bytes.count, isDigit(bytes[index]) { index += 1 }
            }
            if index < bytes.count, bytes[index] == UInt8(ascii: "e") || bytes[index] == UInt8(ascii: "E") {
                index += 1
                if index < bytes.count, bytes[index] == UInt8(ascii: "+") || bytes[index] == UInt8(ascii: "-") { index += 1 }
                guard index < bytes.count, isDigit(bytes[index]) else { throw error("Exponent part is missing a number") }
                while index < bytes.count, isDigit(bytes[index]) { index += 1 }
            }
            let literal = String(decoding: bytes[start..<index], as: UTF8.self)
            guard let value = Double(literal) else { throw error("Invalid number") }
            return value
        }

        func isDigit(_ byte: UInt8) -> Bool {
            byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9")
        }
    }
}
