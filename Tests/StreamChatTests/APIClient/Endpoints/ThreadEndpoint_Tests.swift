//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadEndpoints_Tests: XCTestCase {
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
