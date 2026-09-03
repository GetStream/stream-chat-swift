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

    func test_updateChannel_buildsCorrectly() {
        let channelPayload: ChannelEditDetailPayload = .unique

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelUpdate(channelPayload.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["data": channelPayload]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .updateChannel(channelPayload: channelPayload)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(channelPayload.apiPath)", endpoint.path.value)
        XCTAssertEqual(expectedEndpoint.method, endpoint.method)
    }
    
    func test_partialChannelUpdate_buildsCorrectly() {
        let channelPayload: ChannelEditDetailPayload = .unique
        let unsetProperties = ["user", "clash"]

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelUpdate(channelPayload.apiPath),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["set": AnyEncodable(channelPayload), "unset": AnyEncodable(unsetProperties)]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .partialChannelUpdate(updates: channelPayload, unsetProperties: unsetProperties)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(channelPayload.apiPath)", endpoint.path.value)
        XCTAssertEqual(expectedEndpoint.method, endpoint.method)
    }

    func test_addMembers_buildsCorrectly() {
        let cid = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])
        let members = userIds.map { MemberInfoRequest(userId: $0, extraData: ["is_premium": true]) }

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelUpdate(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["add_members": AnyEncodable(members), "hide_history": AnyEncodable(true)]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .addMembers(
            cid: cid,
            members: members,
            hideHistory: true
        )

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)", endpoint.path.value)
    }
    
    func test_addMembers_withHideHistoryBefore_buildsCorrectly() {
        let cid = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])
        let members = userIds.map { MemberInfoRequest(userId: $0, extraData: ["is_premium": true]) }
        let hideHistoryBefore = Date()

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelUpdate(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["add_members": AnyEncodable(members), "hide_history_before": AnyEncodable(hideHistoryBefore)]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .addMembers(
            cid: cid,
            members: members,
            hideHistory: true,
            hideHistoryBefore: hideHistoryBefore
        )

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)", endpoint.path.value)
    }

    func test_removeMembers_buildsCorrectly() {
        let cid = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelUpdate(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["remove_members": userIds]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .removeMembers(cid: cid, userIds: userIds)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)", endpoint.path.value)
    }

    func test_inviteMembers_buildsCorrectly() {
        let cid = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique, UserId.unique])

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelUpdate(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["invites": userIds]
        )

        let endpoint: Endpoint<EmptyResponse> = .inviteMembers(cid: cid, userIds: userIds)
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/" + cid.apiPath, endpoint.path.value)
    }

    func test_acceptInvite_buildsCorrectly() {
        let cid = ChannelId.unique
        let message = "Welcome"

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelUpdate(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ChannelInvitePayload(
                accept: true,
                reject: false,
                message: .init(message: message)
            )
        )

        let endpoint: Endpoint<EmptyResponse> = .acceptInvite(cid: cid, message: message)
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/" + cid.apiPath, endpoint.path.value)
    }

    func test_rejectInvite_buildsCorrectly() {
        let cid = ChannelId.unique

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelUpdate(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ChannelInvitePayload(
                accept: false,
                reject: true,
                message: nil
            )
        )

        let endpoint: Endpoint<EmptyResponse> = .rejectInvite(cid: cid)
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/" + cid.apiPath, endpoint.path.value)
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

    func test_enableSlowMode_buildsCorrectly() {
        let cid = ChannelId.unique
        let cooldownDuration = Int.random(in: 0...120)

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelUpdate(cid.apiPath),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["set": ["cooldown": cooldownDuration]]
        )

        let endpoint = Endpoint<EmptyResponse>.enableSlowMode(cid: cid, cooldownDuration: cooldownDuration)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)", endpoint.path.value)
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

    func test_freezeChannel_buildsCorrectly() {
        let cid = ChannelId.unique
        let freeze = Bool.random()

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelUpdate(cid.apiPath),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["set": ["frozen": freeze]]
        )

        let endpoint: Endpoint<EmptyResponse> = .freezeChannel(freeze, cid: cid)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/" + cid.apiPath, endpoint.path.value)
    }
}
