//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - JSONDecoder Stream

extension JSONDecoder {
    /// A convenience method returning RawJSON dictionary.
    func decodeRawJSON(from data: Data?) throws -> [String: RawJSON] {
        guard let data, !data.isEmpty else { return [:] }
        let rawJSON = try decode([String: RawJSON].self, from: data)
        return rawJSON
    }
}

extension JSONDecoder {
    /// A default `JSONDecoder`.
    static let `default`: JSONDecoder = streamCore
    
    static let stream: JSONDecoder = streamCore
}

// MARK: - JSONEncoder Stream

extension JSONEncoder {
    /// A default `JSONEncoder`.
    static let `default`: JSONEncoder = streamCore
    
    static let stream: JSONEncoder = streamCore
}

// MARK: - Helper AnyEncodable

struct AnyEncodable: Encodable, Sendable {
    let encodable: (Encodable & Sendable)

    init(_ encodable: Encodable & Sendable) {
        self.encodable = encodable
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try encodable.encode(to: &container)
    }
}

extension Encodable where Self: Sendable {
    var asAnyEncodable: AnyEncodable {
        AnyEncodable(self)
    }
}

extension Encodable {
    // We need this helper in order to encode AnyEncodable with a singleValueContainer,
    // this is needed for the encoder to apply the encoding strategies of the inner type (encodable).
    // More details about this in the following thread:
    // https://forums.swift.org/t/how-to-encode-objects-of-unknown-type/12253/10
    fileprivate func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }
}
