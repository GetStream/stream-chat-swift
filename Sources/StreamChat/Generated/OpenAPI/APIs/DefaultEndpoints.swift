//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum EndpointPath: Codable {
    case connect
    case sync
    case users
    case guest
    case search
    case og
    case unread
    case pushPreferences

    case members
    case partialMemberUpdate(userId: UserId, cid: ChannelId)

    case threads
    case thread(messageId: MessageId)
    case markThreadRead(cid: ChannelId)
    case markThreadUnread(cid: ChannelId)

    case channels
    case groupedChannels
    case createChannel(String)
    case updateChannel(String)
    case deleteChannel(String)
    case channelUpdate(String)
    case muteChannel(Bool)
    case showChannel(String, Bool)
    case truncateChannel(String)
    case markChannelRead(String)
    case markChannelUnread(String)
    case markAllChannelsRead
    case markChannelsDelivered
    case channelEvent(String)
    case stopWatchingChannel(String)
    case pinnedMessages(String)
    case uploadChannelAttachment(channelId: String, type: String)
    case uploadAttachment(String)

    case sendMessage(ChannelId)
    case message(MessageId)
    case editMessage(MessageId)
    case deleteMessage(MessageId)
    case pinMessage(MessageId)
    case unpinMessage(MessageId)
    case replies(MessageId)
    case reactions(MessageId)
    case addReaction(MessageId)
    case deleteReaction(MessageId, MessageReactionType)
    case messageAction(MessageId)
    case translateMessage(MessageId)

    // Drafts
    case drafts
    case draftMessage(ChannelId)

    // Reminders
    case reminders
    case reminder(MessageId)

    case banMember
    case flagUser(Bool)
    case flagMessage(Bool)
    case muteUser(Bool)

    case callToken(String)
    case createCall(String)

    case deleteFile(String)
    case deleteImage(String)

    case liveLocations

    case polls
    case pollsQuery
    case poll(pollId: String)
    case pollOption(pollId: String, optionId: String)
    case pollOptions(pollId: String)
    case pollVotes(pollId: String)
    case pollVoteInMessage(messageId: MessageId, pollId: String)
    case pollVote(messageId: MessageId, pollId: String, voteId: String)

    case userGroups
    case userGroupSearch
    case userGroup(id: String)
    case userGroupMembers(id: String)
    case userGroupMembersDelete(id: String)

    case rolesSearch

    case blockUsers
    case createDevice
    case deleteDevice
    case getApp
    case getBlockedUsers
    case listDevices
    case unblockUsers

    var value: String {
        switch self {
        case .connect: return "connect"
        case .sync: return "sync"
        case .users: return "users"
        case .guest: return "guest"
        case .search: return "search"
        case .og: return "og"
        case .unread: return "unread"
        case .pushPreferences: return "push_preferences"

        case .members: return "members"
        case let .partialMemberUpdate(userId, cid):
            return "channels/\(cid.apiPath)/member/\(userId)"

        case .threads:
            return "threads"
        case let .thread(threadId):
            return "threads/\(threadId)"
        case let .markThreadRead(cid):
            return "channels/\(cid.apiPath)/read"
        case let .markThreadUnread(cid):
            return "channels/\(cid.apiPath)/unread"

        case .liveLocations: return "users/live_locations"

        case .channels: return "channels"
        case .groupedChannels: return "channels/grouped"
        case let .createChannel(queryString): return "channels/\(queryString)/query"
        case let .updateChannel(queryString): return "channels/\(queryString)/query"
        case let .deleteChannel(payloadPath): return "channels/\(payloadPath)"
        case let .channelUpdate(payloadPath): return "channels/\(payloadPath)"
        case let .muteChannel(mute): return "moderation/\(mute ? "mute" : "unmute")/channel"
        case let .showChannel(channelId, show): return "channels/\(channelId)/\(show ? "show" : "hide")"
        case let .truncateChannel(channelId): return "channels/\(channelId)/truncate"
        case let .markChannelRead(channelId): return "channels/\(channelId)/read"
        case let .markChannelUnread(channelId): return "channels/\(channelId)/unread"
        case .markAllChannelsRead: return "channels/read"
        case .markChannelsDelivered: return "channels/delivered"
        case let .channelEvent(channelId): return "channels/\(channelId)/event"
        case let .stopWatchingChannel(channelId): return "channels/\(channelId)/stop-watching"
        case let .pinnedMessages(channelId): return "channels/\(channelId)/pinned_messages"
        case let .uploadChannelAttachment(channelId, type): return "channels/\(channelId)/\(type)"
        case let .uploadAttachment(type): return "uploads/\(type)"

        case let .sendMessage(channelId): return "channels/\(channelId.apiPath)/message"
        case let .message(messageId): return "messages/\(messageId)"
        case let .editMessage(messageId): return "messages/\(messageId)"
        case let .deleteMessage(messageId): return "messages/\(messageId)"
        case let .pinMessage(messageId): return "messages/\(messageId)"
        case let .unpinMessage(messageId): return "messages/\(messageId)"
        case let .replies(messageId): return "messages/\(messageId)/replies"
        case let .reactions(messageId): return "messages/\(messageId)/reactions"
        case let .addReaction(messageId): return "messages/\(messageId)/reaction"
        case let .deleteReaction(messageId, reaction): return "messages/\(messageId)/reaction/\(reaction.rawValue)"
        case let .messageAction(messageId): return "messages/\(messageId)/action"
        case let .translateMessage(messageId): return "messages/\(messageId)/translate"

        case .drafts: return "drafts/query"
        case let .draftMessage(channelId): return "channels/\(channelId.apiPath)/draft"

        case .reminders: return "reminders/query"
        case let .reminder(messageId): return "messages/\(messageId)/reminders"

        case .banMember: return "moderation/ban"
        case let .flagUser(flag): return "moderation/\(flag ? "flag" : "unflag")"
        case let .flagMessage(flag): return "moderation/\(flag ? "flag" : "unflag")"
        case let .muteUser(mute): return "moderation/\(mute ? "mute" : "unmute")"
        case let .callToken(callId): return "calls/\(callId)"
        case let .createCall(queryString): return "channels/\(queryString)/call"
        case let .deleteFile(channelId): return "channels/\(channelId)/file"
        case let .deleteImage(channelId): return "channels/\(channelId)/image"
        case .polls: return "polls"
        case .pollsQuery: return "polls/query"
        case let .poll(pollId: pollId): return "polls/\(pollId)"
        case let .pollOption(pollId: pollId, optionId: optionId): return "polls/\(pollId)/options/\(optionId)"
        case let .pollOptions(pollId: pollId): return "polls/\(pollId)/options"
        case let .pollVotes(pollId: pollId): return "polls/\(pollId)/votes"
        case let .pollVoteInMessage(messageId: messageId, pollId: pollId): return "messages/\(messageId)/polls/\(pollId)/vote"
        case let .pollVote(messageId: messageId, pollId: pollId, voteId: voteId): return "messages/\(messageId)/polls/\(pollId)/vote/\(voteId)"

        case .userGroups: return "usergroups"
        case .userGroupSearch: return "usergroups/search"
        case let .userGroup(id): return "usergroups/\(id)"
        case let .userGroupMembers(id): return "usergroups/\(id)/members"
        case let .userGroupMembersDelete(id): return "usergroups/\(id)/members/delete"

        case .rolesSearch: return "roles/search"

        case .blockUsers:
            return "/api/v2/users/block"
        case .createDevice:
            return "/api/v2/devices"
        case .deleteDevice:
            return "/api/v2/devices"
        case .getApp:
            return "/api/v2/app"
        case .getBlockedUsers:
            return "/api/v2/users/block"
        case .listDevices:
            return "/api/v2/devices"
        case .unblockUsers:
            return "/api/v2/users/unblock"
        }
    }
}

final class Endpoint<ResponseType: Decodable>: Codable, Sendable {
    let path: EndpointPath
    let method: EndpointMethod
    let queryItems: (Encodable & Sendable)?
    let requiresConnectionId: Bool
    let requiresToken: Bool
    let body: (Encodable & Sendable)?

    init(
        path: EndpointPath,
        method: EndpointMethod,
        queryItems: (Encodable & Sendable)? = nil,
        requiresConnectionId: Bool = false,
        requiresToken: Bool = true,
        body: (Encodable & Sendable)? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.requiresConnectionId = requiresConnectionId
        self.requiresToken = requiresToken
        self.body = body
    }

    private enum CodingKeys: String, CodingKey {
        case path
        case method
        case queryItems
        case requiresConnectionId
        case requiresToken
        case body
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(EndpointPath.self, forKey: .path)
        method = try container.decode(EndpointMethod.self, forKey: .method)
        queryItems = try container.decodeIfPresent(Data.self, forKey: .queryItems)
        requiresConnectionId = try container.decode(Bool.self, forKey: .requiresConnectionId)
        requiresToken = try container.decode(Bool.self, forKey: .requiresToken)
        body = try container.decodeIfPresent(Data.self, forKey: .body)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        try container.encode(method, forKey: .method)
        if let queryItems = try queryItems?.encodedAsData() {
            try container.encode(queryItems, forKey: .queryItems)
        }
        try container.encode(requiresConnectionId, forKey: .requiresConnectionId)
        try container.encode(requiresToken, forKey: .requiresToken)
        if let body = try body?.encodedAsData() {
            try container.encode(body, forKey: .body)
        }
    }
}

private extension Encodable where Self: Sendable {
    func encodedAsData() throws -> Data {
        if let data = self as? Data {
            return data
        }
        return try JSONEncoder.stream.encode(AnyEncodable(self))
    }
}

enum EndpointMethod: String, Codable, Equatable {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
    case put = "PUT"
}

extension Endpoint {
    static func blockUsers(blockUsersRequest: BlockUsersRequest, requiresConnectionId: Bool = false) -> Endpoint<BlockUsersResponse> {
        return .init(
            path: .blockUsers,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: blockUsersRequest
        )
    }

    static func createDevice(createDeviceRequest: CreateDeviceRequest, requiresConnectionId: Bool = false) -> Endpoint<Response> {
        return .init(
            path: .createDevice,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createDeviceRequest
        )
    }

    static func deleteDevice(id: String, requiresConnectionId: Bool = false) -> Endpoint<Response> {
        return .init(
            path: .deleteDevice,
            method: .delete,
            queryItems: [
                "id": APIHelper.convertAnyToString(id)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getApp(requiresConnectionId: Bool = false) -> Endpoint<GetApplicationResponse> {
        return .init(
            path: .getApp,
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getBlockedUsers(requiresConnectionId: Bool = false) -> Endpoint<GetBlockedUsersResponse> {
        return .init(
            path: .getBlockedUsers,
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func listDevices(requiresConnectionId: Bool = false) -> Endpoint<ListDevicesResponse> {
        return .init(
            path: .listDevices,
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func unblockUsers(unblockUsersRequest: UnblockUsersRequest, requiresConnectionId: Bool = false) -> Endpoint<UnblockUsersResponse> {
        return .init(
            path: .unblockUsers,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: unblockUsersRequest
        )
    }
}
