//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

public struct AnyEndpoint: Equatable {
    public let path: EndpointPath
    public let method: EndpointMethod
    public let queryItems: AnyEncodable?
    public let requiresConnectionId: Bool
    public let body: AnyEncodable?
    public let payloadType: Decodable.Type

    public init<T: Decodable>(_ endpoint: Endpoint<T>) {
        path = endpoint.path
        method = endpoint.method
        queryItems = endpoint.queryItems?.asAnyEncodable
        requiresConnectionId = endpoint.requiresConnectionId
        body = endpoint.body?.asAnyEncodable
        payloadType = T.self
    }

    public static func == (lhs: AnyEndpoint, rhs: AnyEndpoint) -> Bool {
        lhs.path.value == rhs.path.value
            && lhs.method == rhs.method
            && lhs.queryItems == rhs.queryItems
            && lhs.requiresConnectionId == rhs.requiresConnectionId
            && lhs.body == rhs.body
            && lhs.payloadType == rhs.payloadType
    }

    func queryItemsAsDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(queryItems)
        guard let requestQueryItems = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "com.getstream.io.any-endpoint", code: 2)
        }
        return requestQueryItems
    }

    func bodyAsDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(body)
        guard let requestBody = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "com.getstream.io.any-endpoint", code: 1)
        }
        return requestBody
    }
}

extension Endpoint {
    /// Test helper exposing the endpoint's query items as a `[String: String]` map.
    /// The generated factories stringify every query value (via `APIHelper`), so a flat
    /// string map matches what the request encoder ultimately sends — and keeps the
    /// per-endpoint tests reading values by key without unwrapping the opaque
    /// `(Encodable & Sendable)?` query payload.
    var queryItemsDictionary: [String: String] {
        guard let dictionary = try? AnyEndpoint(self).queryItemsAsDictionary() else { return [:] }
        return dictionary.compactMapValues { $0 as? String }
    }
}

func AssertEqualEndpoint<A, B>(
    _ lhs: Endpoint<A>?,
    _ rhs: Endpoint<B>?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let lhs = lhs, let rhs = rhs else {
        XCTFail("Endpoints cannot be optional")
        return
    }
    XCTAssertEqual(AnyEndpoint(lhs), AnyEndpoint(rhs))
}
