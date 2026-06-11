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

    func test_getReplies_buildsGeneratedEndpointWithSortAsJSON() throws {
        let sort = [SortParamRequest(direction: -1, field: "created_at")]
        let endpoint: Endpoint<GetRepliesResponse> = .getReplies(
            parentId: "message-id",
            limit: 25,
            idGte: nil,
            idGt: nil,
            idLte: nil,
            idLt: nil,
            idAround: nil,
            sort: sort
        )

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/messages/message-id/replies")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.queryItems?["limit"] ?? nil, "25")
        let sortJSON = try XCTUnwrap(endpoint.queryItems?["sort"] ?? nil)
        XCTAssertEqual(try JSONDecoder.stream.decode([SortParamRequest].self, from: Data(sortJSON.utf8)), sort)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }

    func test_search_buildsGeneratedEndpoint() throws {
        let payload = SearchPayload(filterConditions: ["cid": .string("messaging:general")], limit: 10, query: "hello")
        let endpoint: Endpoint<SearchResponse> = .search(payload: payload)

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/search")
        XCTAssertEqual(endpoint.method, .get)
        let payloadJSON = try XCTUnwrap(endpoint.queryItems?["payload"] ?? nil)
        XCTAssertEqual(try JSONDecoder.stream.decode(SearchPayload.self, from: Data(payloadJSON.utf8)), payload)
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
