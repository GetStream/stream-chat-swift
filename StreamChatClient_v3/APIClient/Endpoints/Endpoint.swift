//
// Endpoint.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct Endpoint<ResponseType: Decodable> {
    let path: String
    let method: Method
    let queryItems: [URLQueryItem]
    let jsonQueryItems: [String: Encodable]? // This applies only for GET requests, can we maybe reuse `body` for that?
    let body: Data?
}

extension Endpoint {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }
}
