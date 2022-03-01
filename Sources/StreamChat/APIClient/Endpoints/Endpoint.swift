//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

struct Endpoint<ResponseType: Decodable>: Codable {
    let path: String
    let method: EndpointMethod
    let queryItems: Encodable?
    let requiresConnectionId: Bool
    let requiresToken: Bool
    let body: Encodable?

    init(
        path: String,
        method: EndpointMethod,
        queryItems: Encodable? = nil,
        requiresConnectionId: Bool = false,
        requiresToken: Bool = true,
        body: Encodable? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.requiresConnectionId = requiresConnectionId
        self.requiresToken = requiresToken
        self.body = body
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case path
        case method
        case queryItems
        case requiresConnectionId
        case requiresToken
        case body
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(String.self, forKey: .path)
        method = try container.decode(EndpointMethod.self, forKey: .method)
        queryItems = try container.decodeIfPresent(Data.self, forKey: .queryItems)
        requiresConnectionId = try container.decode(Bool.self, forKey: .requiresConnectionId)
        requiresToken = try container.decode(Bool.self, forKey: .requiresToken)
        body = try container.decodeIfPresent(Data.self, forKey: .body)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        try container.encode(method, forKey: .method)
        if let queryItemsData = try queryItems?.encodedAsData() {
            try container.encode(queryItemsData, forKey: .queryItems)
        }
        try container.encode(requiresConnectionId, forKey: .requiresConnectionId)
        try container.encode(requiresToken, forKey: .requiresToken)
        if let body = try body?.encodedAsData() {
            try container.encode(body, forKey: .body)
        }
    }
}

private extension Encodable {
    func encodedAsData() throws -> Data {
        try JSONEncoder.stream.encode(AnyEncodable(self))
    }
}

enum EndpointMethod: String, Codable {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// A type representing empty response of an Endpoint.
public struct EmptyResponse: Decodable {}

/// A type representing empty body for `.post` Endpoints.
/// Our backend currently expects a body (not `nil`), even if it's empty.
struct EmptyBody: Codable, Equatable {}
