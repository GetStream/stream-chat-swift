//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class MemberEndpoints_Tests: XCTestCase {
    func test_channelMembers_buildsCorrectly() {
        let query = ChannelMemberListQuery<NameAndImageExtraData>(
            cid: .unique,
            filter: .equal(.id, to: "Luke"),
            sort: [.init(key: .createdAt)],
            pagination: [.offset(3)]
        )
        
        let expectedEndpoint = Endpoint<ChannelMemberListPayload<DefaultExtraData.User>>(
            path: "members",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["payload": query]
        )
        
        // Build endpoint.
        let endpoint: Endpoint<ChannelMemberListPayload<DefaultExtraData.User>> = .channelMembers(query: query)
        
        // Assert endpoint is built correctly.
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}
