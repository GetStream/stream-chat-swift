//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import StreamChat

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

    func bodyAsDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(body)
        guard let requestBody = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "com.getstream.io.any-endpoint", code: 1)
        }
        return requestBody
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
