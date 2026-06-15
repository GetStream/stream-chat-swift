//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadEndpoint_Tests: XCTestCase {
    func test_queryThreads_buildsGeneratedEndpoint() {
        let request = QueryThreadsRequest(limit: 10, watch: true)
        let endpoint: Endpoint<QueryThreadsResponse> = .queryThreads(queryThreadsRequest: request)

        XCTAssertEqual(endpoint.path, "/api/v2/chat/threads")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertTrue(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? QueryThreadsRequest, request)
    }

    func test_getThread_buildsGeneratedEndpoint() {
        let endpoint: Endpoint<GetThreadResponse> = .getThread(
            messageId: "message-id",
            watch: true,
            replyLimit: 10,
            participantLimit: 5,
            memberLimit: 3
        )

        XCTAssertEqual(endpoint.path, "/api/v2/chat/threads/message-id")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.queryItems?["watch"] ?? nil, "true")
        XCTAssertEqual(endpoint.queryItems?["reply_limit"] ?? nil, "10")
        XCTAssertTrue(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }

    func test_updateThreadPartial_buildsGeneratedEndpoint() {
        let request = UpdateThreadPartialRequest(set: ["title": .string("Updated")])
        let endpoint: Endpoint<UpdateThreadPartialResponse> = .updateThreadPartial(
            messageId: "message-id",
            updateThreadPartialRequest: request
        )

        XCTAssertEqual(endpoint.path, "/api/v2/chat/threads/message-id")
        XCTAssertEqual(endpoint.method, .patch)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? UpdateThreadPartialRequest, request)
    }
}
