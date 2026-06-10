//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelEndpoints_Tests: XCTestCase {
    func test_queryChannels_buildsGeneratedEndpoint() {
        let request = QueryChannelsRequest(limit: 10, presence: true, state: true, watch: true)
        let endpoint: Endpoint<QueryChannelsResponse> = .queryChannels(queryChannelsRequest: request)

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/channels")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertTrue(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? QueryChannelsRequest, request)
    }

    func test_channelQueryWrapper_buildsCompatibilityEndpoint() {
        let cid = ChannelId(type: .messaging, id: "general")
        let query = ChannelQuery(cid: cid)

        let endpoint: Endpoint<ChannelStateResponse> = .channelQuery(query, requiresConnectionId: false)

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/channels/messaging/general/query")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }

    func test_channelQueryWrapper_buildsGeneratedDistinctChannelEndpoint() {
        let query = ChannelQuery(
            id: nil,
            type: .messaging,
            channelPayload: .init(
                name: nil,
                imageURL: nil,
                team: nil,
                members: ["user-id"],
                invites: [],
                filterTags: [],
                extraData: [:]
            )
        )

        let endpoint: Endpoint<ChannelStateResponse> = .channelQuery(query, requiresConnectionId: false)

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/channels/messaging/query")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }

    func test_channelWatchersWrapper_buildsGeneratedChannelQueryEndpoint() {
        let cid = ChannelId(type: .messaging, id: "general")
        let endpoint: Endpoint<ChannelStateResponse> = .channelWatchers(query: .init(cid: cid))

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/channels/messaging/general/query")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertTrue(endpoint.requiresConnectionId)
        XCTAssertEqual(
            endpoint.body as? ChannelGetOrCreateRequest,
            ChannelGetOrCreateRequest(state: true, watch: true, watchers: PaginationParams(limit: 30))
        )
    }

    func test_pinnedMessagesWrapper_buildsCompatibilityEndpoint() {
        let cid = ChannelId(type: .messaging, id: "general")
        let endpoint: Endpoint<MessageListPayload> = .pinnedMessages(cid: cid, query: .init(pageSize: 10))

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/channels/messaging/general/pinned_messages")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }
}
