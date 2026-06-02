//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ModerationEndpoints_Tests: XCTestCase {
    func test_muteUserReplacement_buildsGeneratedEndpoint() {
        let request = MuteRequest(targetIds: ["user-id"])
        let endpoint: Endpoint<MuteResponse> = .mute(muteRequest: request)

        XCTAssertEqual(endpoint.path.value, "/api/v2/moderation/mute")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? MuteRequest, request)
    }

    func test_unbanMemberWrapper_buildsCompatibilityEndpoint() {
        let cid = ChannelId(type: .messaging, id: "general")
        let endpoint: Endpoint<EmptyResponse> = .unbanMember("user-id", cid: cid)

        XCTAssertEqual(endpoint.path.value, "moderation/ban")
        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.queryItems?["target_user_id"] ?? nil, "user-id")
        XCTAssertEqual(endpoint.queryItems?["channel_cid"] ?? nil, cid.rawValue)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }

    func test_unmuteUserWrapper_buildsCompatibilityEndpoint() {
        let endpoint: Endpoint<EmptyResponse> = .unmuteUser("user-id")

        XCTAssertEqual(endpoint.path.value, "moderation/unmute")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }

    func test_flagMessageWrapper_buildsGeneratedFlagEndpoint() {
        let endpoint: Endpoint<FlagResponse> = .flagMessage(true, with: "message-id", reason: "spam")

        XCTAssertEqual(endpoint.path.value, "/api/v2/moderation/flag")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }

    func test_unflagUserWrapper_buildsCompatibilityEndpoint() {
        let endpoint: Endpoint<FlagResponse> = .flagUser(false, with: "user-id")

        XCTAssertEqual(endpoint.path.value, "moderation/unflag")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }

    func test_unflagMessageWrapper_buildsCompatibilityEndpoint() {
        let endpoint: Endpoint<FlagResponse> = .flagMessage(false, with: "message-id")

        XCTAssertEqual(endpoint.path.value, "moderation/unflag")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }
}
