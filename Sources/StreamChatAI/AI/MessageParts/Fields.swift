//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Lenient reads from a JSON object: a field of the wrong type reads as missing.
struct Fields {
    let object: [String: Any]

    init(_ object: [String: Any]) { self.object = object }

    func string(_ key: String) -> String? {
        guard let value = object[key] as? String, !value.isEmpty else { return nil }
        return value
    }

    func int(_ key: String) -> Int? {
        guard let number = object[key] as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        return number.intValue
    }

    func fields(_ key: String) -> Fields? {
        (object[key] as? [String: Any]).map(Fields.init)
    }

    /// An RFC 3339 time, with or without fractional seconds.
    func date(_ key: String) -> Date? {
        guard let value = string(key) else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    func json(_ key: String) -> Data? {
        guard let value = object[key], !(value is NSNull), JSONSerialization.isValidJSONObject(value) else { return nil }
        return try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
    }
}
