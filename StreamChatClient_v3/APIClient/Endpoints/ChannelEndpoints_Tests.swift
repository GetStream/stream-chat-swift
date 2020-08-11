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
            (.init(cid: channelID, options: .state), true),
            (.init(cid: channelID, options: .presence), true),
            (.init(cid: channelID, options: .watch), true),
            (.init(cid: channelID, options: .all), true),
            (.init(cid: channelID, options: []), false)
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

    func test_updateChannel_buildsCorrectly() {
        let channelPayload: ChannelEditDetailPayload<DefaultDataTypes> = .unique

        let expectedEndpoint = Endpoint<EmptyResponse>(path: "channels/\(channelPayload.cid.type)/\(channelPayload.cid.id)",
                                                       method: .post,
                                                       queryItems: nil,
                                                       requiresConnectionId: false,
                                                       body: ["data": channelPayload])

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .updateChannel(channelPayload: channelPayload)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }

    func test_deleteChannel_buildsCorrectly() {
        let cid = ChannelId.unique

        let expectedEndpoint = Endpoint<EmptyResponse>(path: "channels/\(cid.type)/\(cid.id)",
                                                       method: .delete,
                                                       queryItems: nil,
                                                       requiresConnectionId: false,
                                                       body: nil)

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .deleteChannel(cid: cid)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }

    func test_hideChannel_buildsCorrectly() {
        let testCases = [true, false]

        for clearHistory in testCases {
            let cid = ChannelId.unique
            let userId = UserId.unique

            let expectedEndpoint = Endpoint<EmptyResponse>(path: "channels/\(cid.type)/\(cid.id)/hide",
                                                           method: .post,
                                                           queryItems: nil,
                                                           requiresConnectionId: false,
                                                           body: HideChannelRequest(userId: userId, clearHistory: clearHistory))

            // Build endpoint
            let endpoint: Endpoint<EmptyResponse> = .hideChannel(cid: cid, userId: userId, clearHistory: clearHistory)

            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        }
    }

    func test_muteChannel_buildsCorrectly() {
        let testCases = [
            (true, "moderation/mute/channel"),
            (false, "moderation/unmute/channel")
        ]

        for (mute, path) in testCases {
            let channelID = ChannelId.unique

            let expectedEndpoint = Endpoint<EmptyResponse>(path: path,
                                                           method: .post,
                                                           queryItems: nil,
                                                           requiresConnectionId: true,
                                                           body: ["channel_cid": channelID])

            // Build endpoint
            let endpoint: Endpoint<EmptyResponse> = .muteChannel(cid: channelID, mute: mute)

            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        }
    }

    func test_showChannel_buildsCorrectly() {
        let cid = ChannelId.unique
        let userId = UserId.unique

        let expectedEndpoint = Endpoint<EmptyResponse>(path: "channels/\(cid.type)/\(cid.id)/show",
                                                       method: .post,
                                                       queryItems: nil,
                                                       requiresConnectionId: false,
                                                       body: ["userId": userId])

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .showChannel(cid: cid, userId: userId)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}

extension ChannelEditDetailPayload where ExtraData == DefaultDataTypes {
    static var unique: Self {
        Self(cid: .unique,
             team: .unique,
             members: [],
             invites: [],
             extraData: .init())
    }
}
