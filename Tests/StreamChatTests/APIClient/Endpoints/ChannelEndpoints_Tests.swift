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
        var query = ChannelQuery(cid: cid)
        query.options = []

        let endpoint: Endpoint<ChannelStateResponse> = .channelQuery(query)

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/channels/messaging/general/query")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }

    func test_channelQueryWrapper_buildsGeneratedDistinctChannelEndpoint() {
        var query = ChannelQuery(
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
        query.options = []

        let endpoint: Endpoint<ChannelStateResponse> = .channelQuery(query)

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/channels/messaging/query")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }

    func test_channelQueryWrapper_whenPresenceOrWatchEnabled_requiresConnectionId() {
        var presenceQuery = ChannelQuery(cid: ChannelId(type: .messaging, id: "general"))
        presenceQuery.options = .presence
        XCTAssertTrue(Endpoint<ChannelStateResponse>.channelQuery(presenceQuery).requiresConnectionId)

        var watchQuery = ChannelQuery(cid: ChannelId(type: .messaging, id: "general"))
        watchQuery.options = .watch
        XCTAssertTrue(Endpoint<ChannelStateResponse>.channelQuery(watchQuery).requiresConnectionId)
    }

    func test_channelQueryWrapper_whenOnlyStateEnabled_doesNotRequireConnectionId() {
        var query = ChannelQuery(cid: ChannelId(type: .messaging, id: "general"))
        query.options = .state

        let endpoint = Endpoint<ChannelStateResponse>.channelQuery(query)

        XCTAssertFalse(endpoint.requiresConnectionId)
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

    func test_pinnedMessagesWrapper_buildsCompatibilityEndpoint() throws {
        let cid = ChannelId(type: .messaging, id: "general")
        let endpoint: Endpoint<MessageListPayload> = .pinnedMessages(cid: cid, query: .init(pageSize: 10))

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/channels/messaging/general/pinned_messages")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
        let payloadString = try XCTUnwrap(endpoint.queryItems?["payload"] ?? nil)
        let payload = try XCTUnwrap(payloadString.data(using: .utf8))
        AssertJSONEqual(payload, ["limit": 10])
    }
}
