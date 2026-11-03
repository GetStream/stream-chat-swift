//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// JavaScript semantics used by the OpenUI Lang reference implementation.
///
/// The language spec is defined by a TypeScript runtime, so expression evaluation, string
/// conversion and comparisons follow JavaScript rules. These helpers reproduce the parts the
/// language relies on so that output matches the reference renderers.
@available(iOS 17.0, macOS 14.0, *)
enum JS {
    // MARK: - Whitespace

    /// ECMAScript `WhiteSpace` + `LineTerminator` code points (used by `trim`, `Number`, `parseFloat`).
    static func isWhitespace(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x20, 0xa0, 0x1680, 0x2028, 0x2029, 0x202f, 0x205f, 0x3000, 0xfeff:
            return true
        case 0x2000...0x200a:
            return true
        default:
            return false
        }
    }

    /// `String.prototype.trim`.
    static func trim(_ string: String) -> String {
        trimEnd(trimStart(string))
    }

    /// `String.prototype.trimStart`.
    static func trimStart(_ string: String) -> String {
        let scalars = string.unicodeScalars
        guard let start = scalars.firstIndex(where: { !isWhitespace($0) }) else { return "" }
        return String(scalars[start...])
    }

    /// `String.prototype.trimEnd`.
    static func trimEnd(_ string: String) -> String {
        let scalars = string.unicodeScalars
        guard let last = scalars.lastIndex(where: { !isWhitespace($0) }) else { return "" }
        return String(scalars[...last])
    }

    // MARK: - Numbers

    /// `Number.prototype.toString()` (ECMA-262 Number::toString with radix 10).
    static func numberToString(_ value: Double) -> String {
        if value.isNaN { return "NaN" }
        if value == 0 { return "0" }
        if value.isInfinite { return value < 0 ? "-Infinity" : "Infinity" }
        if value < 0 { return "-" + numberToString(-value) }

        let (digits, n) = shortestDigits(value)
        let k = digits.count

        if k <= n && n <= 21 {
            return digits + String(repeating: "0", count: n - k)
        }
        if n > 0 && n <= 21 {
            let index = digits.index(digits.startIndex, offsetBy: n)
            return String(digits[..<index]) + "." + String(digits[index...])
        }
        if n > -6 && n <= 0 {
            return "0." + String(repeating: "0", count: -n) + digits
        }
        let exponent = n - 1
        let sign = exponent < 0 ? "-" : "+"
        if k == 1 {
            return digits + "e" + sign + String(abs(exponent))
        }
        return String(digits.prefix(1)) + "." + String(digits.dropFirst()) + "e" + sign + String(abs(exponent))
    }

    /// Shortest round-trip decimal digits `s` and exponent `n` such that `value = 0.s × 10^n`.
    private static func shortestDigits(_ value: Double) -> (digits: String, n: Int) {
        // Swift's description is the shortest representation that round-trips.
        let description = value.description
        var mantissa = Substring(description)
        var exponent = 0
        if let eIndex = description.firstIndex(where: { $0 == "e" || $0 == "E" }) {
            mantissa = description[..<eIndex]
            exponent = Int(description[description.index(after: eIndex)...]) ?? 0
        }
        let integerPart: Substring
        let fractionPart: Substring
        if let dot = mantissa.firstIndex(of: ".") {
            integerPart = mantissa[..<dot]
            fractionPart = mantissa[mantissa.index(after: dot)...]
        } else {
            integerPart = mantissa
            fractionPart = ""
        }
        var allDigits = Array(integerPart + fractionPart)
        var pointPosition = integerPart.count
        while let first = allDigits.first, first == "0" {
            allDigits.removeFirst()
            pointPosition -= 1
        }
        while let last = allDigits.last, last == "0" {
            allDigits.removeLast()
        }
        if allDigits.isEmpty { return ("0", 1) }
        return (String(allDigits), pointPosition + exponent)
    }

    /// `Number(string)` — ECMAScript StringToNumber.
    static func stringToNumber(_ string: String) -> Double {
        let trimmed = trim(string)
        if trimmed.isEmpty { return 0 }
        let bytes = Array(trimmed.utf8)

        if bytes.count > 2, bytes[0] == UInt8(ascii: "0") {
            let radix: Int?
            switch bytes[1] {
            case UInt8(ascii: "x"), UInt8(ascii: "X"): radix = 16
            case UInt8(ascii: "o"), UInt8(ascii: "O"): radix = 8
            case UInt8(ascii: "b"), UInt8(ascii: "B"): radix = 2
            default: radix = nil
            }
            if let radix {
                var result = 0.0
                for byte in bytes[2...] {
                    guard let digit = digitValue(byte), digit < radix else { return .nan }
                    result = result * Double(radix) + Double(digit)
                }
                return result
            }
        }

        guard let (value, length) = scanDecimalLiteral(bytes, from: 0), length == bytes.count else {
            return .nan
        }
        return value
    }

    /// `parseFloat(string)`.
    static func parseFloat(_ string: String) -> Double {
        let bytes = Array(trimStart(string).utf8)
        guard let (value, _) = scanDecimalLiteral(bytes, from: 0) else { return .nan }
        return value
    }

    /// Scans the longest ECMAScript `StrDecimalLiteral` prefix (including `Infinity`).
    private static func scanDecimalLiteral(_ bytes: [UInt8], from start: Int) -> (Double, Int)? {
        var i = start
        var negative = false
        if i < bytes.count, bytes[i] == UInt8(ascii: "+") || bytes[i] == UInt8(ascii: "-") {
            negative = bytes[i] == UInt8(ascii: "-")
            i += 1
        }
        let infinity = Array("Infinity".utf8)
        if bytes.count - i >= infinity.count, Array(bytes[i..<(i + infinity.count)]) == infinity {
            return (negative ? -.infinity : .infinity, i + infinity.count)
        }
        let digitsStart = i
        var integerDigits = 0
        while i < bytes.count, isDecimalDigit(bytes[i]) {
            i += 1
            integerDigits += 1
        }
        var fractionDigits = 0
        if i < bytes.count, bytes[i] == UInt8(ascii: ".") {
            var j = i + 1
            while j < bytes.count, isDecimalDigit(bytes[j]) {
                j += 1
                fractionDigits += 1
            }
            if integerDigits > 0 || fractionDigits > 0 {
                i = j
            }
        }
        guard integerDigits > 0 || fractionDigits > 0 else { return nil }
        var end = i
        if i < bytes.count, bytes[i] == UInt8(ascii: "e") || bytes[i] == UInt8(ascii: "E") {
            var j = i + 1
            if j < bytes.count, bytes[j] == UInt8(ascii: "+") || bytes[j] == UInt8(ascii: "-") {
                j += 1
            }
            let exponentStart = j
            while j < bytes.count, isDecimalDigit(bytes[j]) {
                j += 1
            }
            if j > exponentStart {
                end = j
            }
        }
        var literal = String(decoding: bytes[digitsStart..<end], as: UTF8.self)
        if literal.hasPrefix(".") { literal = "0" + literal }
        guard let magnitude = Double(literal) else { return nil }
        return (negative ? -magnitude : magnitude, end)
    }

    private static func isDecimalDigit(_ byte: UInt8) -> Bool {
        byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9")
    }

    private static func digitValue(_ byte: UInt8) -> Int? {
        switch byte {
        case UInt8(ascii: "0")...UInt8(ascii: "9"): return Int(byte - UInt8(ascii: "0"))
        case UInt8(ascii: "a")...UInt8(ascii: "z"): return Int(byte - UInt8(ascii: "a")) + 10
        case UInt8(ascii: "A")...UInt8(ascii: "Z"): return Int(byte - UInt8(ascii: "A")) + 10
        default: return nil
        }
    }

    /// The language's lenient numeric coercion (builtins `toNumber`): numbers pass through,
    /// numeric strings convert (invalid ones become `0`), booleans become `1`/`0`, anything else `0`.
    static func toNumber(_ value: OpenUIValue?) -> Double {
        switch value {
        case .number(let number):
            return number
        case .string(let string):
            let number = stringToNumber(string)
            return number.isNaN ? 0 : number
        case .bool(let bool):
            return bool ? 1 : 0
        default:
            return 0
        }
    }

    /// `Math.round` — rounds half up towards +∞.
    static func round(_ value: Double) -> Double {
        guard value.isFinite else { return value }
        let floor = value.rounded(.down)
        return value - floor >= 0.5 ? floor + 1 : floor
    }

    /// `Math.min` over two values (propagates NaN).
    static func min(_ lhs: Double, _ rhs: Double) -> Double {
        if lhs.isNaN || rhs.isNaN { return .nan }
        return Swift.min(lhs, rhs)
    }

    /// `Math.max` over two values (propagates NaN).
    static func max(_ lhs: Double, _ rhs: Double) -> Double {
        if lhs.isNaN || rhs.isNaN { return .nan }
        return Swift.max(lhs, rhs)
    }

    // MARK: - Conversions

    /// `String(value)`.
    static func toString(_ value: OpenUIValue?) -> String {
        guard let value else { return "undefined" }
        switch value {
        case .null: return "null"
        case .bool(let bool): return bool ? "true" : "false"
        case .number(let number): return numberToString(number)
        case .string(let string): return string
        case .array(let items):
            return items.map { item -> String in
                if item.isNull { return "" }
                return toString(item)
            }.joined(separator: ",")
        case .object, .element, .expression:
            return "[object Object]"
        }
    }

    /// JavaScript truthiness.
    static func isTruthy(_ value: OpenUIValue?) -> Bool {
        guard let value else { return false }
        switch value {
        case .null: return false
        case .bool(let bool): return bool
        case .number(let number): return number != 0 && !number.isNaN
        case .string(let string): return !string.isEmpty
        case .array, .object, .element, .expression: return true
        }
    }

    /// `typeof value`.
    static func typeOf(_ value: OpenUIValue?) -> String {
        guard let value else { return "undefined" }
        switch value {
        case .string: return "string"
        case .number: return "number"
        case .bool: return "boolean"
        case .null, .array, .object, .element, .expression: return "object"
        }
    }

    /// `Array.isArray(value) ? "array" : typeof value`.
    static func jsType(_ value: OpenUIValue?) -> String {
        if case .array = value { return "array" }
        return typeOf(value)
    }

    // MARK: - Equality

    /// Abstract (loose) equality `==`.
    ///
    /// Arrays and objects are compared structurally; the reference implementation compares them by
    /// identity, which has no value-semantics equivalent.
    static func looseEquals(_ lhs: OpenUIValue?, _ rhs: OpenUIValue?) -> Bool {
        let leftNullish = isNullish(lhs)
        let rightNullish = isNullish(rhs)
        if leftNullish || rightNullish { return leftNullish && rightNullish }
        guard let lhs, let rhs else { return false }

        switch (lhs, rhs) {
        case (.number(let a), .number(let b)):
            return a == b
        case (.string(let a), .string(let b)):
            return sameCodeUnits(a, b)
        case (.bool(let a), .bool(let b)):
            return a == b
        case (.number(let a), .string(let b)):
            return a == stringToNumber(b)
        case (.string(let a), .number(let b)):
            return stringToNumber(a) == b
        case (.bool(let a), _):
            return looseEquals(.number(a ? 1 : 0), rhs)
        case (_, .bool(let b)):
            return looseEquals(lhs, .number(b ? 1 : 0))
        case (.number, _), (.string, _):
            return looseEquals(lhs, .string(toString(rhs)))
        case (_, .number), (_, .string):
            return looseEquals(.string(toString(lhs)), rhs)
        default:
            return lhs == rhs
        }
    }

    /// `value == null` (true for `null` and `undefined`).
    static func isNullish(_ value: OpenUIValue?) -> Bool {
        switch value {
        case .none, .some(.null): return true
        default: return false
        }
    }

    /// `SameValueZero` (used by `Array.prototype.includes`).
    static func sameValueZero(_ lhs: OpenUIValue?, _ rhs: OpenUIValue?) -> Bool {
        switch (lhs, rhs) {
        case (.number(let a)?, .number(let b)?):
            return a == b || (a.isNaN && b.isNaN)
        case (.string(let a)?, .string(let b)?):
            return sameCodeUnits(a, b)
        default:
            return lhs == rhs
        }
    }

    /// String equality as JavaScript has it: UTF-16 code units, not Swift's canonical equivalence,
    /// under which `"é"` and `"e\u{301}"` are equal.
    static func sameCodeUnits(_ lhs: String, _ rhs: String) -> Bool {
        lhs.utf16.elementsEqual(rhs.utf16)
    }

    // MARK: - Property access

    /// `value[key]` for own properties (no prototype lookups).
    static func property(of value: OpenUIValue?, key: String) -> OpenUIValue? {
        guard let value else { return nil }
        switch value {
        case .object(let object):
            return object[key]
        case .array(let items):
            if key == "length" { return .number(Double(items.count)) }
            if let index = arrayIndex(key), index < items.count { return items[index] }
            return nil
        case .string(let string):
            let units = Array(string.utf16)
            if key == "length" { return .number(Double(units.count)) }
            if let index = arrayIndex(key), index < units.count {
                return .string(String(decoding: [units[index]], as: UTF16.self))
            }
            return nil
        case .element(let element):
            return element.property(key)
        case .null, .bool, .number, .expression:
            return nil
        }
    }

    /// Canonical array index (`"0"`, `"12"`; not `"01"` or `"-1"`).
    static func arrayIndex(_ key: String) -> Int? {
        guard !key.isEmpty, key.utf8.allSatisfy({ $0 >= UInt8(ascii: "0") && $0 <= UInt8(ascii: "9") }) else {
            return nil
        }
        if key.count > 1 && key.hasPrefix("0") { return nil }
        return Int(key)
    }

    // MARK: - JSON

    /// `JSON.stringify(value)`. Returns `nil` for `undefined`.
    static func jsonStringify(_ value: OpenUIValue?) -> String? {
        guard let value else { return nil }
        var output = ""
        writeJSON(value, into: &output)
        return output
    }

    static func writeJSON(_ value: OpenUIValue, into output: inout String) {
        switch value {
        case .null:
            output += "null"
        case .bool(let bool):
            output += bool ? "true" : "false"
        case .number(let number):
            output += number.isFinite ? numberToString(number) : "null"
        case .string(let string):
            writeJSONString(string, into: &output)
        case .array(let items):
            output += "["
            for (index, item) in items.enumerated() {
                if index > 0 { output += "," }
                writeJSON(item, into: &output)
            }
            output += "]"
        case .object(let object):
            writeJSONObject(object.entries, into: &output)
        case .element(let element):
            writeJSON(element.jsonValue, into: &output)
        case .expression(let node):
            writeJSON(node.jsonValue, into: &output)
        }
    }

    private static func writeJSONObject(_ entries: [(key: String, value: OpenUIValue)], into output: inout String) {
        output += "{"
        for (index, entry) in entries.enumerated() {
            if index > 0 { output += "," }
            writeJSONString(entry.key, into: &output)
            output += ":"
            writeJSON(entry.value, into: &output)
        }
        output += "}"
    }

    /// `JSON.stringify` string quoting (ECMA-262 QuoteJSONString).
    static func writeJSONString(_ string: String, into output: inout String) {
        output += "\""
        for scalar in string.unicodeScalars {
            switch scalar {
            case "\"": output += "\\\""
            case "\\": output += "\\\\"
            case "\u{08}": output += "\\b"
            case "\u{0C}": output += "\\f"
            case "\n": output += "\\n"
            case "\r": output += "\\r"
            case "\t": output += "\\t"
            default:
                if scalar.value < 0x20 {
                    output += String(format: "\\u%04x", scalar.value)
                } else {
                    output.unicodeScalars.append(scalar)
                }
            }
        }
        output += "\""
    }
}
