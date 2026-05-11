//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DraftEndpoints_Tests: XCTestCase {
    func test_queryDrafts_buildsGeneratedEndpoint() {
        let request = QueryDraftsRequest(limit: 20)
        let endpoint: Endpoint<QueryDraftsResponse> = .queryDrafts(queryDraftsRequest: request)

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/drafts/query")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? QueryDraftsRequest, request)
    }

    func test_getDraft_buildsGeneratedEndpoint() {
        let endpoint: Endpoint<GetDraftResponse> = .getDraft(type: "messaging", id: "general", parentId: "parent")

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/channels/messaging/general/draft")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.queryItems?["parent_id"] ?? nil, "parent")
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }
}
