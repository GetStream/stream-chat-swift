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
}
