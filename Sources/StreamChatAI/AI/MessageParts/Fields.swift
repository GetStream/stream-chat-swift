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

    func json(_ key: String) -> Data? {
        guard let value = object[key], !(value is NSNull), JSONSerialization.isValidJSONObject(value) else { return nil }
        return try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
    }
}
