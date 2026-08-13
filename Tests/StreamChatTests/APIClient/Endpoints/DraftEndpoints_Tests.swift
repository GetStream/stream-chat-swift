//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DraftEndpoints_Tests: XCTestCase {
    func test_drafts() throws {
        let query = DraftListQuery()
        let endpoint = Endpoint<DraftListPayloadResponse>.drafts(query: query)
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()
        let expectedBody: [String: Any] = [
            "limit": 25,
            "sort": [
                ["field": "created_at", "direction": -1]
            ]
        ]

        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "drafts/query")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }

    func test_getDraftMessage() throws {
        let cid = ChannelId(type: .messaging, id: "123")
        let threadId = "thread-id"

        let endpoint = Endpoint<DraftPayloadResponse>.getDraftMessage(
            channelId: cid,
            threadId: threadId
        )

        let queryItems = try AnyEndpoint(endpoint).queryItemsAsDictionary()
        let expectedQueryItems: [String: Any] = [
            "parent_id": "thread-id"
        ]

        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.path.value, "channels/messaging/123/draft")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertNil(endpoint.body)
        AssertDictionary(queryItems, expectedQueryItems)
    }

    func test_getDraftMessage_withoutThreadId() throws {
        let cid = ChannelId(type: .messaging, id: "123")

        let endpoint = Endpoint<DraftPayloadResponse>.getDraftMessage(
            channelId: cid,
            threadId: nil
        )

        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.path.value, "channels/messaging/123/draft")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertNil(endpoint.body)
        XCTAssertNil(endpoint.queryItems)
    }

    func test_deleteDraftMessage() throws {
        let cid = ChannelId(type: .messaging, id: "123")
        let threadId = "thread-id"

        let endpoint = Endpoint<EmptyResponse>.deleteDraftMessage(
            channelId: cid,
            threadId: threadId
        )

        let body = try AnyEndpoint(endpoint).bodyAsDictionary()
        let expectedBody: [String: Any] = [
            "parent_id": "thread-id"
        ]

        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.path.value, "channels/messaging/123/draft")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }

    func test_deleteDraftMessage_withoutThreadId() throws {
        let cid = ChannelId(type: .messaging, id: "123")

        let endpoint = Endpoint<EmptyResponse>.deleteDraftMessage(
            channelId: cid,
            threadId: nil
        )

        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.path.value, "channels/messaging/123/draft")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertNil(endpoint.body)
    }
}
