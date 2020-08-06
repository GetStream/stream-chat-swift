//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

final class ChannelEndpoints_Tests: XCTestCase {
    func test_channels_buildsCorrectly() {
        let filter = Filter.in("member", ["Luke"])

        let testCases: [(ChannelListQuery, Bool)] = [
            (.init(filter: filter, options: .state), true),
            (.init(filter: filter, options: .presence), true),
            (.init(filter: filter, options: .watch), true),
            (.init(filter: filter, options: .all), true),
            (.init(filter: filter, options: []), false)
        ]

        for (query, requiresConnectionId) in testCases {
            let expectedEndpoint = Endpoint<ChannelListPayload<DefaultDataTypes>>(path: "channels",
                                                                                  method: .get,
                                                                                  queryItems: nil,
                                                                                  requiresConnectionId: requiresConnectionId,
                                                                                  body: ["payload": query])

            // Build endpoint
            let endpoint: Endpoint<ChannelListPayload<DefaultDataTypes>> = .channels(query: query)

            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        }
    }

    func test_channel_buildsCorrectly() {
        let channelID = ChannelId(type: .livestream, id: "qwerty")

        let testCases: [(ChannelQuery<DefaultDataTypes>, Bool)] = [
            (.init(channelId: channelID, options: .state), true),
            (.init(channelId: channelID, options: .presence), true),
            (.init(channelId: channelID, options: .watch), true),
            (.init(channelId: channelID, options: .all), true),
            (.init(channelId: channelID, options: []), false)
        ]

        for (query, requiresConnectionId) in testCases {
            let expectedEndpoint =
                Endpoint<ChannelPayload<DefaultDataTypes>>(path: "channels/\(query.cid.type.rawValue)/\(query.cid.id)/query",
                                                           method: .post,
                                                           queryItems: nil,
                                                           requiresConnectionId: requiresConnectionId,
                                                           body: query)

            // Build endpoint
            let endpoint: Endpoint<ChannelPayload<DefaultDataTypes>> = .channel(query: query)

            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        }
    }
}
