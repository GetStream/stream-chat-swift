//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Dictionary alias for JSON objects.
/// Uses `String: any Sendable` to represent loosely typed JSON values.
@available(iOS 15.0, macOS 12.0, *)
typealias JsonMap = [String: any Sendable]

/// Array alias for JSON arrays.
/// Elements are loosely typed JSON values.
@available(iOS 15.0, macOS 12.0, *)
typealias JsonArray = [any Sendable]

/// Helpers for reading, coercing, and encoding loosely typed JSON values.
///
/// A2UI payloads arrive as untyped JSON, so the renderer needs a single place
/// that defines how values are coerced. The coercion rules implemented here
/// follow the "Type conversion" section of the A2UI v1.0 specification.
@available(iOS 15.0, macOS 12.0, *)
enum Json {
    /// Returns the value with JSON `null` normalized to `nil`.
    /// Use this before storing or comparing decoded values.
    static func normalized(_ value: (any Sendable)?) -> (any Sendable)? {
        guard let value, !(value is NSNull) else { return nil }
        return value
    }

    /// Returns `true` when the value represents JSON `null`.
    /// Both `nil` and `NSNull` are treated as null.
    /// Whether objects and arrays in a value nest deeper than `limit`.
    /// Stops at the limit, so a hostile value can't exhaust the stack.
    static func exceedsDepth(_ value: (any Sendable)?, limit: Int) -> Bool {
        let children: [(any Sendable)?]
        if let map = map(value) {
            children = Array(map.values)
        } else if let array = array(value) {
            children = array
        } else {
            return false
        }
        guard limit > 0 else { return true }
        return children.contains { exceedsDepth($0, limit: limit - 1) }
    }

    static func isNull(_ value: (any Sendable)?) -> Bool {
        normalized(value) == nil
    }

    /// Converts a JSON value to a string using the A2UI conversion rules.
    ///
    /// Numbers and booleans use their standard representation, `null` becomes an
    /// empty string, and objects and arrays are stringified as JSON so that all
    /// renderers agree on the result.
    static func stringify(_ value: (any Sendable)?) -> String {
        guard let value = normalized(value) else { return "" }
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return stringifyNumber(number)
        case let bool as Bool:
            return bool ? "true" : "false"
        case let array as JsonArray:
            return encodeToString(array) ?? "[]"
        case let map as JsonMap:
            return encodeToString(map) ?? "{}"
        default:
            return String(describing: value)
        }
    }

    /// Reads a string value, coercing non-string JSON values.
    /// Returns `nil` only when the value is missing or null.
    static func string(_ value: (any Sendable)?) -> String? {
        guard let value = normalized(value) else { return nil }
        if let string = value as? String { return string }
        return stringify(value)
    }

    /// Reads a numeric value from a JSON payload.
    /// Numeric strings are parsed so that text input can drive numeric bindings.
    /// Infinity and NaN are rejected, because JSON cannot carry them.
    static func double(_ value: (any Sendable)?) -> Double? {
        guard let value = normalized(value) else { return nil }
        let double: Double?
        if let number = value as? NSNumber {
            double = number.doubleValue
        } else if let string = value as? String {
            double = Double(string.trimmingCharacters(in: .whitespaces))
        } else {
            double = nil
        }
        guard let double, double.isFinite else { return nil }
        return double
    }

    /// Reads an integer value from a JSON payload.
    /// Fractional numbers are truncated towards zero; values outside `Int`'s range are rejected.
    static func int(_ value: (any Sendable)?) -> Int? {
        guard let double = double(value) else { return nil }
        return Int(exactly: double.rounded(.towardZero))
    }

    /// Reads a boolean value from a JSON payload.
    /// Numbers are truthy when non-zero and `"true"`/`"false"` strings are parsed.
    static func bool(_ value: (any Sendable)?) -> Bool? {
        guard let value = normalized(value) else { return nil }
        if let bool = value as? Bool { return bool }
        if let number = value as? NSNumber { return number.doubleValue != 0 }
        if let string = value as? String {
            switch string.lowercased() {
            case "true": return true
            case "false": return false
            default: return nil
            }
        }
        return nil
    }

    /// Reads an array value from a JSON payload.
    /// Returns `nil` when the value is not an array.
    static func array(_ value: (any Sendable)?) -> JsonArray? {
        normalized(value) as? JsonArray
    }

    /// Reads an object value from a JSON payload.
    /// Returns `nil` when the value is not an object.
    static func map(_ value: (any Sendable)?) -> JsonMap? {
        normalized(value) as? JsonMap
    }

    /// Reads an array of strings, coercing individual elements.
    /// Elements that cannot be coerced are dropped.
    static func stringArray(_ value: (any Sendable)?) -> [String]? {
        guard let array = array(value) else { return nil }
        return array.compactMap { string($0) }
    }

    /// Compares two JSON values for structural equality.
    /// `nil` and `NSNull` are considered equal.
    static func isEqual(_ lhs: (any Sendable)?, _ rhs: (any Sendable)?) -> Bool {
        let left = normalized(lhs)
        let right = normalized(rhs)
        if left == nil && right == nil { return true }
        guard let left, let right else { return false }
        return NSDictionary(dictionary: ["value": left]).isEqual(to: ["value": right])
    }

    /// Encodes a JSON value to UTF-8 data.
    /// Returns `nil` when the value is not JSON serializable.
    static func encode(_ value: any Sendable, pretty: Bool = false) -> Data? {
        // `JSONSerialization` raises an Objective-C exception, which `try` cannot
        // catch, for values it cannot encode such as NaN. Wrapping the value in an
        // array lets `isValidJSONObject` check top-level scalars too.
        guard JSONSerialization.isValidJSONObject([value]) else { return nil }
        let options: JSONSerialization.WritingOptions = pretty
            ? [.prettyPrinted, .sortedKeys, .fragmentsAllowed]
            : [.fragmentsAllowed]
        return try? JSONSerialization.data(withJSONObject: value, options: options)
    }

    /// Encodes a JSON value to a UTF-8 string.
    /// Returns `nil` when the value is not JSON serializable.
    static func encodeToString(_ value: any Sendable, pretty: Bool = false) -> String? {
        guard let data = encode(value, pretty: pretty) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Encodes a JSON value with sorted keys, for use as a stable identity.
    ///
    /// `JSONSerialization` does not guarantee key order, so anything that keys
    /// a cache by an encoded payload must sort the keys first.
    static func canonicalString(_ value: any Sendable) -> String {
        guard JSONSerialization.isValidJSONObject([value]),
              let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys, .fragmentsAllowed]) else {
            return String(describing: value)
        }
        return String(data: data, encoding: .utf8) ?? String(describing: value)
    }

    /// Decodes a JSON string into a loosely typed value.
    /// Returns `nil` when the string is not valid JSON.
    static func decode(_ string: String) -> (any Sendable)? {
        guard let data = string.data(using: .utf8) else { return nil }
        return decode(data)
    }

    /// Decodes JSON data into a loosely typed value.
    /// Returns `nil` when the data is not valid JSON.
    static func decode(_ data: Data) -> (any Sendable)? {
        guard let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else {
            return nil
        }
        return native(object)
    }

    /// Decodes a JSON string into an object.
    /// Returns `nil` when the string is not a JSON object.
    static func decodeMap(_ string: String) -> JsonMap? {
        decode(string) as? JsonMap
    }

    /// Decodes JSON data into an object.
    /// Returns `nil` when the data is not a JSON object.
    static func decodeMap(_ data: Data) -> JsonMap? {
        decode(data) as? JsonMap
    }

    /// Converts `JSONSerialization` output into Swift values.
    ///
    /// Foundation numbers are turned into `Bool`, `Int` or `Double`, because an
    /// `NSNumber` holding 0 or 1 also casts to `Bool`, which would render a count of
    /// one as `true`.
    static func native(_ value: Any) -> any Sendable {
        switch value {
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() { return number.boolValue }
            if CFNumberIsFloatType(number) { return number.doubleValue }
            return number.intValue
        case let string as String:
            return string
        case let array as [Any]:
            return array.map { native($0) }
        case let map as [String: Any]:
            return map.mapValues { native($0) }
        default:
            return NSNull()
        }
    }

    private static func stringifyNumber(_ number: NSNumber) -> String {
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
            return number.boolValue ? "true" : "false"
        }
        let double = number.doubleValue
        if double.rounded() == double, abs(double) < 1e15 {
            return String(Int64(double))
        }
        return String(double)
    }
}
