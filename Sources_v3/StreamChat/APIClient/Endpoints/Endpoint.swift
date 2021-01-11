//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

struct Endpoint<ResponseType: Decodable> {
    let path: String
    let method: EndpointMethod
    let queryItems: Encodable?
    let requiresConnectionId: Bool
    let body: Encodable?
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
