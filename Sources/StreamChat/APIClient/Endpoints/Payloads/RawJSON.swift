//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public indirect enum RawJSON: Codable, Hashable {
    case double(Double)
    case string(String)
    case bool(Bool)
    case dictionary([String: RawJSON])
    case array([RawJSON])
    case `nil`

    public init(from decoder: Decoder) throws {
        let singleValueContainer = try decoder.singleValueContainer()
        if let value = try? singleValueContainer.decode(Bool.self) {
            self = .bool(value)
            return
        } else if let value = try? singleValueContainer.decode(String.self) {
            self = .string(value)
            return
        } else if let value = try? singleValueContainer.decode(Double.self) {
            self = .double(value)
            return
        } else if let value = try? singleValueContainer.decode([String: RawJSON].self) {
            self = .dictionary(value)
            return
        } else if let value = try? singleValueContainer.decode([RawJSON].self) {
            self = .array(value)
            return
        } else if singleValueContainer.decodeNil() {
            self = .nil
            return
        }
        throw DecodingError
            .dataCorrupted(
                DecodingError
                    .Context(codingPath: decoder.codingPath, debugDescription: "Could not find reasonable type to map to JSONValue")
            )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case let .double(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        case let .string(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        case let .dictionary(value): try container.encode(value)
        case .nil: try container.encodeNil()
        }
    }
}

extension RawJSON {
    public var string: String? {
        switch self {
        case let .string(value):
            return value
        default:
            return nil
        }
    }

    public var double: Double? {
        switch self {
        case let .double(value):
            return value
        default:
            return nil
        }
    }

    public var bool: Bool? {
        switch self {
        case let .bool(value):
            return value
        default:
            return nil
        }
    }

    public var dictionary: [String: RawJSON]? {
        switch self {
        case let .dictionary(value):
            return value
        default:
            return nil
        }
    }

    public var array: [RawJSON]? {
        switch self {
        case let .array(value):
            return value
        default:
            return nil
        }
    }

    public var isNil: Bool {
        switch self {
        case .nil:
            return true
        default:
            return false
        }
    }
}
