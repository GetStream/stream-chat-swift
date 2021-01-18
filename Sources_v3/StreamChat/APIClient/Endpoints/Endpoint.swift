//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

struct Endpoint<ResponseType: Decodable> {
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
}

enum EndpointMethod: String {
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
