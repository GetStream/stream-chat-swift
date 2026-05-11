//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageEndpoints_Tests: XCTestCase {
    func test_getMessage_buildsGeneratedEndpoint() {
        let endpoint: Endpoint<GetMessageResponse> = .getMessage(id: "message-id")

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/messages/message-id")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }

    func test_deleteMessage_buildsGeneratedEndpointWithQueryItems() {
        let endpoint: Endpoint<DeleteMessageResponse> = .deleteMessage(
            id: "message-id",
            hard: true,
            deletedBy: "moderator-id",
            deleteForMe: false
        )

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/messages/message-id")
        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.queryItems?["hard"] ?? nil, "true")
        XCTAssertEqual(endpoint.queryItems?["deleted_by"] ?? nil, "moderator-id")
        XCTAssertEqual(endpoint.queryItems?["delete_for_me"] ?? nil, "false")
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }

    func test_updateMessagePartial_buildsGeneratedEndpoint() {
        let request = UpdateMessagePartialRequest(set: ["text": .string("Updated")], skipEnrichUrl: true)
        let endpoint: Endpoint<UpdateMessagePartialResponse> = .updateMessagePartial(
            id: "message-id",
            updateMessagePartialRequest: request
        )

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/messages/message-id")
        XCTAssertEqual(endpoint.method, .put)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? UpdateMessagePartialRequest, request)
    }
}
