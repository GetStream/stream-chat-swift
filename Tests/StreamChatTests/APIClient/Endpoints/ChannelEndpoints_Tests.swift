//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelEndpoints_Tests: XCTestCase {
    func test_channels_buildsCorrectly() {
        let filter: Filter<ChannelListFilterScope> = .containMembers(userIds: [.unique])

        func channelListQuery(options: QueryOptions) -> ChannelListQuery {
            var query: ChannelListQuery = .init(filter: filter)
            query.options = options
            return query
        }

        let testCases: [(ChannelListQuery, Bool)] = [
            (channelListQuery(options: .state), true),
            (channelListQuery(options: .presence), true),
            (channelListQuery(options: .watch), true),
            (channelListQuery(options: .all), true),
            (channelListQuery(options: []), false)
        ]

        for (query, requiresConnectionId) in testCases {
            let expectedEndpoint = Endpoint<ChannelListPayload>(
                path: .channels,
                method: .get,
                queryItems: nil,
                requiresConnectionId: requiresConnectionId,
                body: ["payload": query]
            )

            // Build endpoint
            let endpoint: Endpoint<ChannelListPayload> = .channels(query: query)

            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
            XCTAssertEqual("channels", endpoint.path.value)
        }
    }

    func test_groupedChannels_buildsCorrectly() {
        let testCases: [(GroupedQueryChannelsRequestBody, Bool)] = [
            (.init(limit: 10, groups: nil, watch: true, presence: false), true),
            (.init(limit: 10, groups: nil, watch: false, presence: true), true),
            (.init(limit: 10, groups: nil, watch: true, presence: true), true),
            (.init(limit: 10, groups: nil, watch: false, presence: false), false)
        ]

        for (request, requiresConnectionId) in testCases {
            let expectedEndpoint = Endpoint<GroupedQueryChannelsPayload>(
                path: .groupedChannels,
                method: .post,
                queryItems: nil,
                requiresConnectionId: requiresConnectionId,
                body: request
            )

            let endpoint: Endpoint<GroupedQueryChannelsPayload> = .groupedChannels(request: request)

            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
            XCTAssertEqual("channels/grouped", endpoint.path.value)
        }
    }

    func test_startTypingEvent_withParentMessageId_buildsCorrectly() {
        let cid = ChannelId.unique
        let messageId = MessageId.unique
        let eventType = EventType.userStartTyping

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .sendEvent(type: cid.type.rawValue, id: cid.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: SendEventRequest(event: EventRequest(parentId: messageId, type: eventType.rawValue))
        )

        let endpoint = Endpoint<EmptyResponse>.startTypingEvent(cid: cid, parentMessageId: messageId)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/chat/channels/\(cid.type.rawValue)/\(cid.id)/event", endpoint.path.value)
    }

    func test_startTypingEvent_withoutParentMessageId_buildsCorrectly() {
        let cid = ChannelId.unique
        let eventType = EventType.userStartTyping

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .sendEvent(type: cid.type.rawValue, id: cid.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: SendEventRequest(event: EventRequest(type: eventType.rawValue))
        )

        let endpoint = Endpoint<EmptyResponse>.startTypingEvent(cid: cid, parentMessageId: nil)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/chat/channels/\(cid.type.rawValue)/\(cid.id)/event", endpoint.path.value)
    }

    func test_stopTypingEvent_withParentMessageId_buildsCorrectly() {
        let cid = ChannelId.unique
        let messageId = MessageId.unique
        let eventType = EventType.userStopTyping

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .sendEvent(type: cid.type.rawValue, id: cid.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: SendEventRequest(event: EventRequest(parentId: messageId, type: eventType.rawValue))
        )

        let endpoint = Endpoint<EmptyResponse>.stopTypingEvent(cid: cid, parentMessageId: messageId)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/chat/channels/\(cid.type.rawValue)/\(cid.id)/event", endpoint.path.value)
    }

    func test_stopTypingEvent_withoutParentMessageId_buildsCorrectly() {
        let cid = ChannelId.unique
        let eventType = EventType.userStopTyping

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .sendEvent(type: cid.type.rawValue, id: cid.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: SendEventRequest(event: EventRequest(type: eventType.rawValue))
        )

        let endpoint = Endpoint<EmptyResponse>.stopTypingEvent(cid: cid, parentMessageId: nil)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/chat/channels/\(cid.type.rawValue)/\(cid.id)/event", endpoint.path.value)
    }

    func test_stopWatching_buildsCorrectly() {
        let cid = ChannelId.unique

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .stopWatchingChannel(type: cid.type.rawValue, id: cid.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: nil
        )

        let endpoint = Endpoint<EmptyResponse>.stopWatchingChannel(type: cid.type.rawValue, id: cid.id)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/chat/channels/\(cid.type.rawValue)/\(cid.id)/stop-watching", endpoint.path.value)
    }

}
