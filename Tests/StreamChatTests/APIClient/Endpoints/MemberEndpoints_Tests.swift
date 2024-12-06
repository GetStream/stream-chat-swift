//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MemberEndpoints_Tests: XCTestCase {
    func test_channelMembers_buildsCorrectly() {
        let query = ChannelMemberListQuery(
            cid: .unique,
            filter: .equal(.id, to: "Luke"),
            sort: [.init(key: .createdAt)]
        )

        let expectedEndpoint = Endpoint<ChannelMemberListPayload>(
            path: .members,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["payload": query]
        )

        // Build endpoint.
        let endpoint: Endpoint<ChannelMemberListPayload> = .channelMembers(query: query)

        // Assert endpoint is built correctly.
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("members", endpoint.path.value)
    }

    func test_partialMemberUpdate_buildsCorrectly() {
        let userId: UserId = "test-user"
        let cid: ChannelId = .unique
        let updates = MemberUpdatePayload(extraData: ["is_premium": .bool(true)])
        let unset: [String] = ["is_cool"]

        let body: [String: AnyEncodable] = [
            "set": AnyEncodable(["is_premium": true]),
            "unset": AnyEncodable(["is_cool"])
        ]
        let expectedEndpoint = Endpoint<PartialMemberUpdateResponse>(
            path: .partialMemberUpdate(userId: userId, cid: cid),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )

        // Build endpoint.
        let endpoint: Endpoint<PartialMemberUpdateResponse> = .partialMemberUpdate(
            userId: userId,
            cid: cid,
            updates: updates,
            unset: unset
        )

        // Assert endpoint is built correctly.
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}
