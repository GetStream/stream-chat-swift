//
// Copyright © 2020 Stream.io Inc. All rights reserved.
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
    case delete = "DELETE"
}

/// A type representing empty response of an Endpoint.
public struct EmptyResponse: Decodable {}
