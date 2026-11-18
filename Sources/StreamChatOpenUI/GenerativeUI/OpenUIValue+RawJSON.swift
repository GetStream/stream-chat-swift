//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatAI

@available(iOS 17.0, macOS 14.0, *)
extension OpenUIValue {
    // The value as JSON, as JavaScript's `JSON.stringify` writes it: components and expressions
    // turn into their plain JSON shapes, and numbers that aren't finite into null.
    var rawJSON: RawJSON {
        plainJSON.plainRawJSON
    }

    private var plainRawJSON: RawJSON {
        switch self {
        case .null, .element, .expression:
            return .nil
        case let .bool(value):
            return .bool(value)
        case let .number(value):
            return .number(value)
        case let .string(value):
            return .string(value)
        case let .array(items):
            return .array(items.map(\.plainRawJSON))
        case let .object(object):
            return .dictionary(Dictionary(object.entries.map { ($0.key, $0.value.plainRawJSON) }, uniquingKeysWith: { _, last in last }))
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension OpenUIObject {
    var rawJSON: [String: RawJSON] {
        guard case let .dictionary(fields) = OpenUIValue.object(self).rawJSON else { return [:] }
        return fields
    }

    // The fields in the order of their keys, which a dictionary doesn't keep, so a value reads
    // the same each time, such as a tool's arguments in the agent's instructions.
    init(rawJSON: [String: RawJSON]) {
        self.init(rawJSON.sorted { $0.key < $1.key }.map { ($0.key, $0.value.openUIValue) })
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension RawJSON {
    var openUIValue: OpenUIValue {
        switch self {
        case .nil:
            return .null
        case let .bool(value):
            return .bool(value)
        case let .number(value):
            return .number(value)
        case let .string(value):
            return .string(value)
        case let .array(items):
            return .array(items.map(\.openUIValue))
        case let .dictionary(fields):
            return .object(OpenUIObject(rawJSON: fields))
        }
    }
}
