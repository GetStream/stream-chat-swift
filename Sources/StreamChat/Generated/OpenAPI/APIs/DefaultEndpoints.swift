//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class Endpoint<ResponseType: Decodable>: Codable, Sendable {
    let path: String
    let method: EndpointMethod
    let queryItems: (Encodable & Sendable)?
    let requiresConnectionId: Bool
    let requiresToken: Bool
    let shouldBeQueuedOffline: Bool
    let body: (Encodable & Sendable)?

    init(
        path: String,
        method: EndpointMethod,
        queryItems: (Encodable & Sendable)? = nil,
        requiresConnectionId: Bool = false,
        requiresToken: Bool = true,
        shouldBeQueuedOffline: Bool = false,
        body: (Encodable & Sendable)? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.requiresConnectionId = requiresConnectionId
        self.requiresToken = requiresToken
        self.shouldBeQueuedOffline = shouldBeQueuedOffline
        self.body = body
    }

    private enum CodingKeys: String, CodingKey {
        case path
        case method
        case queryItems
        case requiresConnectionId
        case requiresToken
        case shouldBeQueuedOffline
        case body
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(String.self, forKey: .path)
        method = try container.decode(EndpointMethod.self, forKey: .method)
        queryItems = try container.decodeIfPresent(Data.self, forKey: .queryItems)
        requiresConnectionId = try container.decode(Bool.self, forKey: .requiresConnectionId)
        requiresToken = try container.decode(Bool.self, forKey: .requiresToken)
        shouldBeQueuedOffline = try container.decode(Bool.self, forKey: .shouldBeQueuedOffline)
        body = try container.decodeIfPresent(Data.self, forKey: .body)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        try container.encode(method, forKey: .method)
        if let queryItems = try queryItems?.encodedAsData() {
            try container.encode(queryItems, forKey: .queryItems)
        }
        try container.encode(requiresConnectionId, forKey: .requiresConnectionId)
        try container.encode(requiresToken, forKey: .requiresToken)
        try container.encode(shouldBeQueuedOffline, forKey: .shouldBeQueuedOffline)
        if let body = try body?.encodedAsData() {
            try container.encode(body, forKey: .body)
        }
    }
}

private extension Encodable where Self: Sendable {
    func encodedAsData() throws -> Data {
        try JSONEncoder.stream.encode(AnyEncodable(self))
    }
}

enum EndpointMethod: String, Codable, Equatable {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
    case put = "PUT"
}

extension Endpoint {
    static func getApp(requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<GetApplicationResponse> {
        .init(
            path: "/api/v2/app",
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }
}
