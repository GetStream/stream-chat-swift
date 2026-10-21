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

    /// An RFC 3339 time, with or without fractional seconds. Before iOS 15 there is no format
    /// style to read one with, so it reads as missing.
    func date(_ key: String) -> Date? {
        guard let value = string(key) else { return nil }
        // A format style is a value that is cheap to make; Foundation keeps the formatter
        // behind it, which is what is expensive.
        guard #available(iOS 15, macOS 12, *) else { return nil }
        return (try? Date(value, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
            ?? (try? Date(value, strategy: Date.ISO8601FormatStyle()))
    }

    func json(_ key: String) -> Data? {
        guard let value = object[key], !(value is NSNull), JSONSerialization.isValidJSONObject(value) else { return nil }
        return try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
    }
}
