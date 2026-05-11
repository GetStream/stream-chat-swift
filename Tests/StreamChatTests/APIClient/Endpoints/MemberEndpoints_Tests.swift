//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MemberEndpoints_Tests: XCTestCase {
    func test_queryMembers_buildsGeneratedEndpoint() {
        let payload = QueryMembersPayload(filterConditions: [:], id: "general", limit: 25, type: "messaging")
        let endpoint: Endpoint<MembersResponse> = .queryMembers(payload: payload)

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/members")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertNotNil(endpoint.queryItems?["payload"] ?? nil)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }

    func test_updateMemberPartial_buildsGeneratedEndpoint() {
        let request = UpdateMemberPartialRequest(set: ["role": .string("moderator")], unset: ["archived"])
        let endpoint: Endpoint<UpdateMemberPartialResponse> = .updateMemberPartial(
            type: "messaging",
            id: "general",
            updateMemberPartialRequest: request
        )

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/channels/messaging/general/member")
        XCTAssertEqual(endpoint.method, .patch)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? UpdateMemberPartialRequest, request)
    }
}
