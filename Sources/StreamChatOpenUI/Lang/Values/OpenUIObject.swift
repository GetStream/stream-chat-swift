//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An insertion-ordered string-keyed map, mirroring JavaScript object semantics.
///
/// Key order is significant in OpenUI: positional component arguments are mapped onto props in
/// the order the library schema declares them, and objects are serialized in insertion order.
/// Re-assigning an existing key keeps its original position; removing a key drops it.
@available(iOS 17.0, macOS 14.0, *)
struct OpenUIObject: Sendable, Hashable {
    private(set) var keys: [String]
    private var storage: [String: OpenUIValue]

    init() {
        keys = []
        storage = [:]
    }

    init<S: Sequence>(_ pairs: S) where S.Element == (String, OpenUIValue) {
        self.init()
        for (key, value) in pairs {
            self[key] = value
        }
    }

    var count: Int { keys.count }
    var isEmpty: Bool { keys.isEmpty }

    /// Values in key order.
    var values: [OpenUIValue] { keys.compactMap { storage[$0] } }

    /// Key/value pairs in key order.
    var entries: [(key: String, value: OpenUIValue)] {
        keys.compactMap { key in storage[key].map { (key, $0) } }
    }

    func contains(_ key: String) -> Bool {
        storage[key] != nil
    }

    /// Gets or sets a value. Assigning `nil` removes the key (like `delete obj[key]`).
    subscript(key: String) -> OpenUIValue? {
        get { storage[key] }
        set {
            if let newValue {
                if storage.updateValue(newValue, forKey: key) == nil {
                    keys.append(key)
                }
            } else {
                removeValue(forKey: key)
            }
        }
    }

    @discardableResult
    mutating func removeValue(forKey key: String) -> OpenUIValue? {
        guard let removed = storage.removeValue(forKey: key) else { return nil }
        if let index = keys.firstIndex(of: key) {
            keys.remove(at: index)
        }
        return removed
    }

    /// Returns a copy with `other`'s entries assigned on top (like `{ ...self, ...other }`).
    func merging(_ other: OpenUIObject) -> OpenUIObject {
        var result = self
        for (key, value) in other.entries {
            result[key] = value
        }
        return result
    }

    func mapValues(_ transform: (OpenUIValue) throws -> OpenUIValue) rethrows -> OpenUIObject {
        var result = OpenUIObject()
        for (key, value) in entries {
            result[key] = try transform(value)
        }
        return result
    }

    /// Order-insensitive equality: JavaScript objects with the same own properties are treated as equal.
    static func == (lhs: OpenUIObject, rhs: OpenUIObject) -> Bool {
        lhs.storage == rhs.storage
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension OpenUIObject: Sequence {
    func makeIterator() -> AnyIterator<(key: String, value: OpenUIValue)> {
        var iterator = entries.makeIterator()
        return AnyIterator { iterator.next() }
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension OpenUIObject: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, OpenUIValue)...) {
        self.init(elements)
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension OpenUIObject {
    // Form state without what password fields hold, at any depth, for anything that leaves the
    // device.
    var withoutSecrets: OpenUIObject {
        OpenUIObject(entries.compactMap { key, value -> (String, OpenUIValue)? in
            guard case .object(let object) = value else { return (key, value) }
            if object["secret"] == .bool(true) { return nil }
            return (key, .object(object.withoutSecrets))
        })
    }
}
