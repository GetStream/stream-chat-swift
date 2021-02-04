//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A `RawJSON` type.
/// Used to store and operate objects of unknown structure that's not possible to decode.
/// https://forums.swift.org/t/new-unevaluated-type-for-decoder-to-allow-later-re-encoding-of-data-with-unknown-structure/11117
indirect enum RawJSON: Codable, Hashable {
    case double(Double)
    case string(String)
    case bool(Bool)
    case dictionary([String: RawJSON])
    case array([RawJSON])
    case `nil`

    init(from decoder: Decoder) throws {
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
    
    func encode(to encoder: Encoder) throws {
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
