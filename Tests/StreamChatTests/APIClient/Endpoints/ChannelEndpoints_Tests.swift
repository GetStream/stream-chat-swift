//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelEndpoints_Tests: XCTestCase {
    func test_channels_buildsCorrectly() throws {
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
            // Build endpoint
            let endpoint = query.endpoint

            // Assert endpoint is built correctly
            XCTAssertEqual(endpoint.method, .post)
            XCTAssertEqual(endpoint.requiresConnectionId, requiresConnectionId)
            XCTAssertEqual("/api/v2/chat/channels", endpoint.path.value)
            let body = try XCTUnwrap(endpoint.body)
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder.default.encode(body)) as? [String: Any])
            XCTAssertNotNil(json["filter_conditions"])
            XCTAssertEqual(json["limit"] as? Int, .channelsPageSize)
            XCTAssertEqual(json["state"] as? Bool, query.options.contains(.state))
            XCTAssertEqual(json["watch"] as? Bool, query.options.contains(.watch))
            XCTAssertEqual(json["presence"] as? Bool, query.options.contains(.presence))
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
