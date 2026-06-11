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
        queryItems = endpoint.queryItems?.mapValues { $0.map(Self.canonicalizingJSONKeyOrder) }.asAnyEncodable
        requiresConnectionId = endpoint.requiresConnectionId
        body = endpoint.body?.asAnyEncodable
        payloadType = T.self
    }

    // JSON-encoded query item values have nondeterministic key order, so two
    // independently built endpoints only compare equal after sorting the keys.
    private static func canonicalizingJSONKeyOrder(_ value: String) -> String {
        guard value.hasPrefix("{") || value.hasPrefix("["),
              let object = try? JSONSerialization.jsonObject(with: Data(value.utf8)),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
              let canonical = String(data: data, encoding: .utf8)
        else { return value }
        return canonical
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
