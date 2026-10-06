//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A JSON value, such as the input schema of a client tool.
///
/// It encodes to plain JSON, so a schema written with it reads the same as one written with
/// any other JSON library, such as the Model Context Protocol SDK's `Value`.
///
/// ```swift
/// let schema: AIJSONValue = [
///     "type": "object",
///     "properties": ["city": ["type": "string"]],
///     "required": ["city"]
/// ]
/// ```
public enum AIJSONValue: Hashable, Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([AIJSONValue])
    case object([String: AIJSONValue])
}

extension AIJSONValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([AIJSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: AIJSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "The value is not JSON.")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case let .bool(value):
            try container.encode(value)
        case let .int(value):
            try container.encode(value)
        case let .double(value):
            try container.encode(value)
        case let .string(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        }
    }
}

extension AIJSONValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension AIJSONValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension AIJSONValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension AIJSONValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension AIJSONValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension AIJSONValue: ExpressibleByStringInterpolation {}

extension AIJSONValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: AIJSONValue...) {
        self = .array(elements)
    }
}

extension AIJSONValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, AIJSONValue)...) {
        self = .object(Dictionary(elements, uniquingKeysWith: { _, last in last }))
    }
}
