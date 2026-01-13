//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadEndpoints_Tests: XCTestCase {
    func test_threads() throws {
        var query = ThreadListQuery(watch: false)
        query.limit = 10
        query.next = "test"
        query.participantLimit = 10
        query.replyLimit = 10

        let endpoint = Endpoint<ThreadListPayload>.threads(query: query)
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()
        let expectedBody: [String: Any] = [
            "limit": 10,
            "next": "test",
            "participant_limit": 10,
            "reply_limit": 10,
            "watch": 0,
            "sort": [
                ["field": "has_unread", "direction": -1],
                ["field": "last_message_at", "direction": -1],
                ["field": "parent_message_id", "direction": -1]
            ]
        ]

        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "threads")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }

    func test_threads_whenWatchIsTrue_thenRequiresConnectionIsTrue() throws {
        var query = ThreadListQuery(watch: true)
        query.limit = 10
        query.next = "test"
        query.participantLimit = 10
        query.replyLimit = 10

        let endpoint = Endpoint<ThreadListPayload>.threads(query: query)
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()
        let expectedBody: [String: Any] = [
            "limit": 10,
            "next": "test",
            "participant_limit": 10,
            "reply_limit": 10,
            "watch": 1,
            "sort": [
                ["field": "has_unread", "direction": -1],
                ["field": "last_message_at", "direction": -1],
                ["field": "parent_message_id", "direction": -1]
            ]
        ]

        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "threads")
        XCTAssertEqual(endpoint.requiresConnectionId, true)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }

    func test_threads_withFilter() throws {
        var query = ThreadListQuery(watch: false, filter: .equal(.createdByUserId, to: "user123"))
        query.limit = 10
        query.next = "test"
        query.participantLimit = 10
        query.replyLimit = 10
        let endpoint = Endpoint<ThreadListPayload>.threads(query: query)
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()
        let expectedBody: [String: Any] = [
            "filter": ["created_by_user_id": ["$eq": "user123"]],
            "limit": 10,
            "next": "test",
            "participant_limit": 10,
            "reply_limit": 10,
            "watch": 0,
            "sort": [
                ["field": "has_unread", "direction": -1],
                ["field": "last_message_at", "direction": -1],
                ["field": "parent_message_id", "direction": -1]
            ]
        ]

        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "threads")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }

    func test_thread() throws {
        var query = ThreadQuery(messageId: "123")
        query.participantLimit = 10
        query.replyLimit = 10
        query.watch = false

        let endpoint = Endpoint<ThreadPayloadResponse>.thread(query: query)
        let queryItems = try AnyEndpoint(endpoint).queryItemsAsDictionary()
        let expectedQueryItems: [String: Any] = [
            "message_id": "123",
            "participant_limit": 10,
            "reply_limit": 10,
            "watch": 0
        ]

        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.path.value, "threads/123")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertNil(endpoint.body)
        AssertDictionary(queryItems, expectedQueryItems)
    }

    func test_thread_whenWatchIsTrue_thenRequiresConnectionIsTrue() throws {
        var query = ThreadQuery(messageId: "123")
        query.participantLimit = 10
        query.replyLimit = 10
        query.watch = true

        let endpoint = Endpoint<ThreadPayloadResponse>.thread(query: query)
        let queryItems = try AnyEndpoint(endpoint).queryItemsAsDictionary()
        let expectedQueryItems: [String: Any] = [
            "message_id": "123",
            "participant_limit": 10,
            "reply_limit": 10,
            "watch": 1
        ]

        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.path.value, "threads/123")
        XCTAssertEqual(endpoint.requiresConnectionId, true)
        XCTAssertNil(endpoint.body)
        AssertDictionary(queryItems, expectedQueryItems)
    }

    func test_partialThreadUpdate() throws {
        let request = ThreadPartialUpdateRequest(
            set: .init(title: "Example"),
            unset: ["custom_thumbnail"]
        )

        let endpoint = Endpoint<ThreadListPayload>.partialThreadUpdate(messageId: "123", request: request)
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()
        let expectedBody: [String: Any] = [
            "set": [
                "title": "Example"
            ],
            "unset": ["custom_thumbnail"]
        ]

        XCTAssertEqual(endpoint.method, .patch)
        XCTAssertEqual(endpoint.path.value, "threads/123")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }

    func test_markRead() throws {
        let cid = ChannelId(type: .messaging, id: "123")
        let endpoint = Endpoint<EmptyResponse>.markThreadRead(
            cid: cid,
            threadId: "test"
        )
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()
        let expectedBody: [String: Any] = [
            "thread_id": "test"
        ]
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "channels/messaging/123/read")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }

    func test_markUnread() throws {
        let cid = ChannelId(type: .messaging, id: "123")
        let endpoint = Endpoint<EmptyResponse>.markThreadUnread(
            cid: cid,
            threadId: "test"
        )
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()
        let expectedBody: [String: Any] = [
            "thread_id": "test"
        ]
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "channels/messaging/123/unread")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }
}
