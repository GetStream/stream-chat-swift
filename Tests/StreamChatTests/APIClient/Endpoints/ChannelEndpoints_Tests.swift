//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    func test_channel_buildsCorrectly() {
        let cid = ChannelId(type: .livestream, id: "qwerty")

        func channelQuery(options: QueryOptions) -> ChannelQuery {
            var query: ChannelQuery = .init(cid: cid)
            query.options = options
            return query
        }

        let testCases: [(ChannelQuery, Bool)] = [
            (channelQuery(options: .state), true),
            (channelQuery(options: .presence), true),
            (channelQuery(options: .watch), true),
            (channelQuery(options: .all), true),
            (channelQuery(options: []), false)
        ]

        for (query, requiresConnectionId) in testCases {
            let expectedEndpoint =
                Endpoint<ChannelPayload>(
                    path: .updateChannel(query.apiPath),
                    method: .post,
                    queryItems: nil,
                    requiresConnectionId: requiresConnectionId,
                    body: query
                )

            // Build endpoint
            let endpoint: Endpoint<ChannelPayload> = .updateChannel(query: query)

            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
            XCTAssertEqual("channels/\(query.apiPath)/query", endpoint.path.value)
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

    func test_deleteChannel_buildsCorrectly() {
        let cid = ChannelId.unique

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .deleteChannel(cid.apiPath),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .deleteChannel(cid: cid)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)", endpoint.path.value)
    }

    func test_truncateChannel_buildsCorrectly() {
        let cid = ChannelId.unique
        let skipPush = false
        let hardDelete = true
        let systemMessage = "System Message"
        let messageBody = MessageRequestBody(id: .unique, user: .dummy(userId: .unique), text: systemMessage, extraData: [:])
        let payload = ChannelTruncateRequestPayload(skipPush: skipPush, hardDelete: hardDelete, message: messageBody)

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .truncateChannel(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: payload
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .truncateChannel(
            cid: cid,
            skipPush: skipPush,
            hardDelete: hardDelete,
            message: messageBody
        )

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)/truncate", endpoint.path.value)
    }

    func test_hideChannel_buildsCorrectly() {
        let testCases = [true, false]

        for clearHistory in testCases {
            let cid = ChannelId.unique

            let expectedEndpoint = Endpoint<EmptyResponse>(
                path: .showChannel(cid.apiPath, false),
                method: .post,
                queryItems: nil,
                requiresConnectionId: false,
                body: ["clear_history": clearHistory]
            )

            // Build endpoint
            let endpoint: Endpoint<EmptyResponse> = .hideChannel(cid: cid, clearHistory: clearHistory)

            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
            XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)/hide", endpoint.path.value)
        }
    }

    func test_muteChannel_buildsCorrectly() {
        let testCases = [true, false]

        for mute in testCases {
            let channelID = ChannelId.unique

            let expectedEndpoint = Endpoint<EmptyResponse>(
                path: .muteChannel(mute),
                method: .post,
                queryItems: nil,
                requiresConnectionId: true,
                body: ["channel_cid": channelID]
            )

            // Build endpoint
            let endpoint: Endpoint<EmptyResponse> = .muteChannel(cid: channelID, mute: mute)

            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
            XCTAssertEqual(mute ? "moderation/mute/channel" : "moderation/unmute/channel", endpoint.path.value)
        }
    }
    
    func test_muteChannelWithExpiration_buildsCorrectly() {
        let testCases = [true, false]
        let expiration = 1_000_000

        for mute in testCases {
            let channelID = ChannelId.unique
            
            let body: [String: AnyEncodable] = [
                "channel_cid": AnyEncodable(channelID),
                "expiration": AnyEncodable(expiration)
            ]

            let expectedEndpoint = Endpoint<EmptyResponse>(
                path: .muteChannel(mute),
                method: .post,
                queryItems: nil,
                requiresConnectionId: true,
                body: body
            )

            // Build endpoint
            let endpoint: Endpoint<EmptyResponse> = .muteChannel(cid: channelID, mute: mute, expiration: expiration)

            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
            XCTAssertEqual(mute ? "moderation/mute/channel" : "moderation/unmute/channel", endpoint.path.value)
        }
    }

    func test_showChannel_buildsCorrectly() {
        let cid = ChannelId.unique

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .showChannel(cid.apiPath, true),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .showChannel(cid: cid)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)/show", endpoint.path.value)
    }

    func test_sendMessage_buildsCorrectly() {
        let cid = ChannelId.unique

        let messageBody = MessageRequestBody(
            id: .unique,
            user: .dummy(userId: .unique),
            text: .unique,
            command: .unique,
            args: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            extraData: [:]
        )

        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: .sendMessage(cid),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "message": AnyEncodable(messageBody),
                "skip_push": AnyEncodable(true),
                "skip_enrich_url": AnyEncodable(false)
            ]
        )

        // Build endpoint
        let endpoint: Endpoint<MessagePayload.Boxed> = .sendMessage(cid: cid, messagePayload: messageBody, skipPush: true, skipEnrichUrl: false)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)/message", endpoint.path.value)
    }

    func test_addMembers_buildsCorrectly() {
        let cid = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelUpdate(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["add_members": AnyEncodable(userIds), "hide_history": AnyEncodable(true)]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .addMembers(cid: cid, userIds: userIds, hideHistory: true)

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

    func test_markRead_buildsCorrectly() {
        let cid = ChannelId.unique

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .markChannelRead(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )

        let endpoint = Endpoint<EmptyResponse>.markRead(cid: cid)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)/read", endpoint.path.value)
    }

    func test_markUnread_buildsCorrectly() {
        let cid = ChannelId.unique
        let messageId = MessageId.unique
        let userId = UserId.unique

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .markChannelUnread(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "message_id": messageId,
                "user_id": userId
            ]
        )

        let endpoint = Endpoint<EmptyResponse>.markUnread(cid: cid, messageId: messageId, userId: userId)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual(endpoint.path.value, "channels/\(cid.type.rawValue)/\(cid.id)/unread")
    }

    func test_markAllRead_buildsCorrectly() {
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .markAllChannelsRead,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )

        let endpoint = Endpoint<EmptyResponse>.markAllRead()

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/read", endpoint.path.value)
    }

    func test_sendEvent_buildsCorrectly() {
        let cid = ChannelId.unique
        let eventType = EventType.userStartTyping

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelEvent(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["event": ["type": eventType]]
        )

        let endpoint = Endpoint<EmptyResponse>.sendEvent(cid: cid, eventType: eventType)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)/event", endpoint.path.value)
    }

    func test_startTypingEvent_withParentMessageId_buildsCorrectly() {
        let cid = ChannelId.unique
        let messageId = MessageId.unique
        let eventType = EventType.userStartTyping

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelEvent(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["event": ["type": eventType.rawValue, "parent_id": messageId]]
        )

        let endpoint = Endpoint<EmptyResponse>.startTypingEvent(cid: cid, parentMessageId: messageId)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)/event", endpoint.path.value)
    }

    func test_startTypingEvent_withoutParentMessageId_buildsCorrectly() {
        let cid = ChannelId.unique
        let eventType = EventType.userStartTyping

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelEvent(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["event": ["type": eventType]]
        )

        let endpoint = Endpoint<EmptyResponse>.startTypingEvent(cid: cid, parentMessageId: nil)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)/event", endpoint.path.value)
    }

    func test_stopTypingEvent_withParentMessageId_buildsCorrectly() {
        let cid = ChannelId.unique
        let messageId = MessageId.unique
        let eventType = EventType.userStopTyping

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelEvent(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["event": ["type": eventType.rawValue, "parent_id": messageId]]
        )

        let endpoint = Endpoint<EmptyResponse>.stopTypingEvent(cid: cid, parentMessageId: messageId)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)/event", endpoint.path.value)
    }

    func test_stopTypingEvent_withoutParentMessageId_buildsCorrectly() {
        let cid = ChannelId.unique
        let eventType = EventType.userStopTyping

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelEvent(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["event": ["type": eventType]]
        )

        let endpoint = Endpoint<EmptyResponse>.stopTypingEvent(cid: cid, parentMessageId: nil)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)/event", endpoint.path.value)
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
            path: .stopWatchingChannel(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: nil
        )

        let endpoint = Endpoint<EmptyResponse>.stopWatching(cid: cid)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(cid.type.rawValue)/\(cid.id)/stop-watching", endpoint.path.value)
    }

    func test_channelWatchers_buildsCorrectly() {
        let cid = ChannelId.unique
        let pagination = Pagination(pageSize: .random(in: 10...100), offset: .random(in: 10...100))
        let query = ChannelWatcherListQuery(cid: cid, pagination: pagination)

        let expectedEndpoint = Endpoint<ChannelPayload>(
            path: .updateChannel(query.cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true, // Observing watchers always requires connection id
            body: query
        )

        let endpoint: Endpoint<ChannelPayload> = .channelWatchers(query: query)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(query.cid.type.rawValue)/\(query.cid.id)/query", endpoint.path.value)
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

    func test_sendCustomEvent_buildsCorrectly() {
        let cid = ChannelId.unique
        let ideaPayload = IdeaEventPayload(idea: .unique)

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .channelEvent(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["event": CustomEventRequestBody(payload: ideaPayload)]
        )

        let endpoint: Endpoint<EmptyResponse> = .sendEvent(ideaPayload, cid: cid)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/" + cid.apiPath + "/event", endpoint.path.value)
    }

    func test_loadPinnedMessages_buildsCorrectly() {
        let cid = ChannelId.unique
        let query = PinnedMessagesQuery(
            pageSize: .unique,
            pagination: .aroundTimestamp(.unique)
        )

        let expectedEndpoint = Endpoint<PinnedMessagesPayload>(
            path: .pinnedMessages(cid.apiPath),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["payload": query]
        )

        let endpoint: Endpoint<PinnedMessagesPayload> = .pinnedMessages(cid: cid, query: query)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/" + cid.apiPath + "/pinned_messages", endpoint.path.value)
    }
}
