//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum EndpointPath: Codable {
    case custom(String)
    case connect
    case sync
    case guest
    case search

    case threads
    case thread(messageId: MessageId)
    case markThreadRead(cid: ChannelId)
    case markThreadUnread(cid: ChannelId)

    case channels
    case groupedChannels
    case createChannel(String)
    case updateChannel(String)
    case channelUpdate(String)
    case markChannelRead(String)
    case markChannelUnread(String)
    case markAllChannelsRead
    case channelEvent(String)

    case message(MessageId)
    case replies(MessageId)

    case addUserGroupMembers(id: String)
    case ban
    case blockUsers
    case castPollVote(messageId: String, pollId: String)
    case createDevice
    case createDraft(type: String, id: String)
    case createPoll
    case createPollOption(pollId: String)
    case createReminder(messageId: String)
    case createUserGroup
    case deleteChannel(type: String, id: String)
    case deleteChannelFile(type: String, id: String)
    case deleteChannelImage(type: String, id: String)
    case deleteDevice
    case deleteDraft(type: String, id: String)
    case deleteFile
    case deleteImage
    case deleteMessage(id: String)
    case deletePoll(pollId: String)
    case deletePollVote(messageId: String, pollId: String, voteId: String)
    case deleteReaction(id: String, type: String)
    case deleteReminder(messageId: String)
    case deleteUserGroup(id: String)
    case flag
    case getApp
    case getBlockedUsers
    case getDraft(type: String, id: String)
    case getOG
    case getPinnedMessages(type: String, id: String)
    case getReactions(id: String)
    case getUserGroup(id: String)
    case getUserLiveLocations
    case hideChannel(type: String, id: String)
    case listDevices
    case listUserGroups
    case markDelivered
    case mute
    case muteChannel
    case queryDrafts
    case queryMembers
    case queryPollVotes(pollId: String)
    case queryReactions(id: String)
    case queryReminders
    case queryUsers
    case removeUserGroupMembers(id: String)
    case runMessageAction(id: String)
    case searchRoles
    case searchUserGroups
    case sendMessage(type: String, id: String)
    case sendReaction(id: String)
    case showChannel(type: String, id: String)
    case stopWatchingChannel(type: String, id: String)
    case translateMessage(id: String)
    case truncateChannel(type: String, id: String)
    case unban
    case unblockUsers
    case unmute
    case unmuteChannel
    case unreadCounts
    case updateLiveLocation
    case updateMemberPartial(type: String, id: String)
    case updateMessage(id: String)
    case updateMessagePartial(id: String)
    case updatePollPartial(pollId: String)
    case updatePushNotificationPreferences
    case updateReminder(messageId: String)
    case updateUserGroup(id: String)
    case updateUsersPartial
    case uploadChannelFile(type: String, id: String)
    case uploadChannelImage(type: String, id: String)
    case uploadFile
    case uploadImage

    var value: String {
        switch self {
        case let .custom(path): return path
        case .connect: return "connect"
        case .sync: return "sync"
        case .guest: return "guest"
        case .search: return "search"

        case .threads:
            return "threads"
        case let .thread(threadId):
            return "threads/\(threadId)"
        case let .markThreadRead(cid):
            return "channels/\(cid.apiPath)/read"
        case let .markThreadUnread(cid):
            return "channels/\(cid.apiPath)/unread"

        case .channels: return "channels"
        case .groupedChannels: return "channels/grouped"
        case let .createChannel(queryString): return "channels/\(queryString)/query"
        case let .updateChannel(queryString): return "channels/\(queryString)/query"
        case let .channelUpdate(payloadPath): return "channels/\(payloadPath)"
        case let .markChannelRead(channelId): return "channels/\(channelId)/read"
        case let .markChannelUnread(channelId): return "channels/\(channelId)/unread"
        case .markAllChannelsRead: return "channels/read"
        case let .channelEvent(channelId): return "channels/\(channelId)/event"

        case let .message(messageId): return "messages/\(messageId)"
        case let .replies(messageId): return "messages/\(messageId)/replies"

        case let .addUserGroupMembers(id: id):
            return "/api/v2/usergroups/\(APIHelper.escapedPathItem(id))/members"
        case .ban:
            return "/api/v2/moderation/ban"
        case .blockUsers:
            return "/api/v2/users/block"
        case let .castPollVote(messageId: messageId, pollId: pollId):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(messageId))/polls/\(APIHelper.escapedPathItem(pollId))/vote"
        case .createDevice:
            return "/api/v2/devices"
        case let .createDraft(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/draft"
        case .createPoll:
            return "/api/v2/polls"
        case let .createPollOption(pollId: pollId):
            return "/api/v2/polls/\(APIHelper.escapedPathItem(pollId))/options"
        case let .createReminder(messageId: messageId):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(messageId))/reminders"
        case .createUserGroup:
            return "/api/v2/usergroups"
        case let .deleteChannel(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))"
        case let .deleteChannelFile(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/file"
        case let .deleteChannelImage(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/image"
        case .deleteDevice:
            return "/api/v2/devices"
        case let .deleteDraft(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/draft"
        case .deleteFile:
            return "/api/v2/uploads/file"
        case .deleteImage:
            return "/api/v2/uploads/image"
        case let .deleteMessage(id: id):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(id))"
        case let .deletePoll(pollId: pollId):
            return "/api/v2/polls/\(APIHelper.escapedPathItem(pollId))"
        case let .deletePollVote(messageId: messageId, pollId: pollId, voteId: voteId):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(messageId))/polls/\(APIHelper.escapedPathItem(pollId))/vote/\(APIHelper.escapedPathItem(voteId))"
        case let .deleteReaction(id: id, type: type):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(id))/reaction/\(APIHelper.escapedPathItem(type))"
        case let .deleteReminder(messageId: messageId):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(messageId))/reminders"
        case let .deleteUserGroup(id: id):
            return "/api/v2/usergroups/\(APIHelper.escapedPathItem(id))"
        case .flag:
            return "/api/v2/moderation/flag"
        case .getApp:
            return "/api/v2/app"
        case .getBlockedUsers:
            return "/api/v2/users/block"
        case let .getDraft(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/draft"
        case .getOG:
            return "/api/v2/og"
        case let .getPinnedMessages(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/pinned_messages"
        case let .getReactions(id: id):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(id))/reactions"
        case let .getUserGroup(id: id):
            return "/api/v2/usergroups/\(APIHelper.escapedPathItem(id))"
        case .getUserLiveLocations:
            return "/api/v2/users/live_locations"
        case let .hideChannel(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/hide"
        case .listDevices:
            return "/api/v2/devices"
        case .listUserGroups:
            return "/api/v2/usergroups"
        case .markDelivered:
            return "/api/v2/chat/channels/delivered"
        case .mute:
            return "/api/v2/moderation/mute"
        case .muteChannel:
            return "/api/v2/chat/moderation/mute/channel"
        case .queryDrafts:
            return "/api/v2/chat/drafts/query"
        case .queryMembers:
            return "/api/v2/chat/members"
        case let .queryPollVotes(pollId: pollId):
            return "/api/v2/polls/\(APIHelper.escapedPathItem(pollId))/votes"
        case let .queryReactions(id: id):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(id))/reactions"
        case .queryReminders:
            return "/api/v2/chat/reminders/query"
        case .queryUsers:
            return "/api/v2/users"
        case let .removeUserGroupMembers(id: id):
            return "/api/v2/usergroups/\(APIHelper.escapedPathItem(id))/members/delete"
        case let .runMessageAction(id: id):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(id))/action"
        case .searchRoles:
            return "/api/v2/roles/search"
        case .searchUserGroups:
            return "/api/v2/usergroups/search"
        case let .sendMessage(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/message"
        case let .sendReaction(id: id):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(id))/reaction"
        case let .showChannel(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/show"
        case let .stopWatchingChannel(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/stop-watching"
        case let .translateMessage(id: id):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(id))/translate"
        case let .truncateChannel(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/truncate"
        case .unban:
            return "/api/v2/moderation/unban"
        case .unblockUsers:
            return "/api/v2/users/unblock"
        case .unmute:
            return "/api/v2/moderation/unmute"
        case .unmuteChannel:
            return "/api/v2/chat/moderation/unmute/channel"
        case .unreadCounts:
            return "/api/v2/chat/unread"
        case .updateLiveLocation:
            return "/api/v2/users/live_locations"
        case let .updateMemberPartial(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/member"
        case let .updateMessage(id: id):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(id))"
        case let .updateMessagePartial(id: id):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(id))"
        case let .updatePollPartial(pollId: pollId):
            return "/api/v2/polls/\(APIHelper.escapedPathItem(pollId))"
        case .updatePushNotificationPreferences:
            return "/api/v2/push_preferences"
        case let .updateReminder(messageId: messageId):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(messageId))/reminders"
        case let .updateUserGroup(id: id):
            return "/api/v2/usergroups/\(APIHelper.escapedPathItem(id))"
        case .updateUsersPartial:
            return "/api/v2/users"
        case let .uploadChannelFile(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/file"
        case let .uploadChannelImage(type: type, id: id):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/image"
        case .uploadFile:
            return "/api/v2/uploads/file"
        case .uploadImage:
            return "/api/v2/uploads/image"
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
    static func addUserGroupMembers(
        id: String,
        addUserGroupMembersRequest: AddUserGroupMembersRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UserGroupResponse> {
        return .init(
            path: .addUserGroupMembers(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: addUserGroupMembersRequest
        )
    }

    static func ban(banRequest: BanRequest, requiresConnectionId: Bool = false) -> Endpoint<EmptyResponse> {
        return .init(
            path: .ban,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: banRequest
        )
    }

    static func blockUsers(blockUsersRequest: BlockUsersRequest, requiresConnectionId: Bool = false) -> Endpoint<BlockUsersResponse> {
        return .init(
            path: .blockUsers,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: blockUsersRequest
        )
    }

    static func castPollVote(
        messageId: String,
        pollId: String,
        castPollVoteRequest: CastPollVoteRequestBody,
        requiresConnectionId: Bool = false
    ) -> Endpoint<PollVotePayloadResponse> {
        return .init(
            path: .castPollVote(messageId: messageId, pollId: pollId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: castPollVoteRequest
        )
    }

    static func createDevice(
        createDeviceRequest: CreateDeviceRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<EmptyResponse> {
        return .init(
            path: .createDevice,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createDeviceRequest
        )
    }

    static func createDraft(
        type: String,
        id: String,
        createDraftRequest: CreateDraftRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<CreateDraftResponse> {
        return .init(
            path: .createDraft(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createDraftRequest
        )
    }

    static func createPoll(
        createPollRequest: CreatePollRequestBody,
        requiresConnectionId: Bool = false
    ) -> Endpoint<PollPayloadResponse> {
        return .init(
            path: .createPoll,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createPollRequest
        )
    }

    static func createPollOption(
        pollId: String,
        createPollOptionRequest: CreatePollOptionRequestBody,
        requiresConnectionId: Bool = false
    ) -> Endpoint<PollOptionResponse> {
        return .init(
            path: .createPollOption(pollId: pollId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createPollOptionRequest
        )
    }

    static func createReminder(
        messageId: String,
        createReminderRequest: CreateReminderRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<CreateReminderResponse> {
        return .init(
            path: .createReminder(messageId: messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createReminderRequest
        )
    }

    static func createUserGroup(
        createUserGroupRequest: CreateUserGroupRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UserGroupResponse> {
        return .init(
            path: .createUserGroup,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createUserGroupRequest
        )
    }

    static func deleteChannel(
        type: String,
        id: String,
        hardDelete: Bool?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<DeleteChannelResponse> {
        return .init(
            path: .deleteChannel(type: type, id: id),
            method: .delete,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "hard_delete": hardDelete
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteChannelFile(
        type: String,
        id: String,
        url: String?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<EmptyResponse> {
        return .init(
            path: .deleteChannelFile(type: type, id: id),
            method: .delete,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "url": url
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteChannelImage(
        type: String,
        id: String,
        url: String?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<EmptyResponse> {
        return .init(
            path: .deleteChannelImage(type: type, id: id),
            method: .delete,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "url": url
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteDevice(id: String, requiresConnectionId: Bool = false) -> Endpoint<EmptyResponse> {
        return .init(
            path: .deleteDevice,
            method: .delete,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "id": id
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteDraft(
        type: String,
        id: String,
        parentId: String?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<EmptyResponse> {
        return .init(
            path: .deleteDraft(type: type, id: id),
            method: .delete,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "parent_id": parentId
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteFile(url: String?, requiresConnectionId: Bool = false) -> Endpoint<EmptyResponse> {
        return .init(
            path: .deleteFile,
            method: .delete,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "url": url
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteImage(url: String?, requiresConnectionId: Bool = false) -> Endpoint<EmptyResponse> {
        return .init(
            path: .deleteImage,
            method: .delete,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "url": url
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteMessage(
        id: String,
        hard: Bool?,
        deleteForMe: Bool?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<DeleteMessageResponse> {
        return .init(
            path: .deleteMessage(id: id),
            method: .delete,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "hard": hard,
                "delete_for_me": deleteForMe
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deletePoll(pollId: String, requiresConnectionId: Bool = false) -> Endpoint<EmptyResponse> {
        return .init(
            path: .deletePoll(pollId: pollId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deletePollVote(
        messageId: String,
        pollId: String,
        voteId: String,
        requiresConnectionId: Bool = false
    ) -> Endpoint<PollVotePayloadResponse> {
        return .init(
            path: .deletePollVote(messageId: messageId, pollId: pollId, voteId: voteId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteReaction(id: String, type: String, requiresConnectionId: Bool = false) -> Endpoint<DeleteReactionResponse> {
        return .init(
            path: .deleteReaction(id: id, type: type),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteReminder(messageId: String, requiresConnectionId: Bool = false) -> Endpoint<EmptyResponse> {
        return .init(
            path: .deleteReminder(messageId: messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteUserGroup(id: String, teamId: String?, requiresConnectionId: Bool = false) -> Endpoint<EmptyResponse> {
        return .init(
            path: .deleteUserGroup(id: id),
            method: .delete,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "team_id": teamId
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func flag(flagRequest: FlagRequest, requiresConnectionId: Bool = false) -> Endpoint<EmptyResponse> {
        return .init(
            path: .flag,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: flagRequest
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

    static func getDraft(
        type: String,
        id: String,
        parentId: String?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<GetDraftResponse> {
        return .init(
            path: .getDraft(type: type, id: id),
            method: .get,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "parent_id": parentId
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getOG(url: String, requiresConnectionId: Bool = false) -> Endpoint<GetOGResponse> {
        return .init(
            path: .getOG,
            method: .get,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "url": url
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getPinnedMessages(
        type: String,
        id: String,
        limit: Int?,
        offset: Int?,
        idGte: String?,
        idGt: String?,
        idLte: String?,
        idLt: String?,
        pinnedAtAfterOrEqual: Date?,
        pinnedAtAfter: Date?,
        pinnedAtBeforeOrEqual: Date?,
        pinnedAtBefore: Date?,
        idAround: String?,
        pinnedAtAround: Date?,
        sort: [SortParamRequest]?,
        memberCustomInclude: [String]?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<GetPinnedMessagesResponse> {
        return .init(
            path: .getPinnedMessages(type: type, id: id),
            method: .get,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "limit": limit,
                "offset": offset,
                "id_gte": idGte,
                "id_gt": idGt,
                "id_lte": idLte,
                "id_lt": idLt,
                "pinned_at_after_or_equal": pinnedAtAfterOrEqual.flatMap { CodableHelper.dateFormatter.string(from: $0) },
                "pinned_at_after": pinnedAtAfter.flatMap { CodableHelper.dateFormatter.string(from: $0) },
                "pinned_at_before_or_equal": pinnedAtBeforeOrEqual.flatMap { CodableHelper.dateFormatter.string(from: $0) },
                "pinned_at_before": pinnedAtBefore.flatMap { CodableHelper.dateFormatter.string(from: $0) },
                "id_around": idAround,
                "pinned_at_around": pinnedAtAround.flatMap { CodableHelper.dateFormatter.string(from: $0) },
                "sort": sort.flatMap { try? CodableHelper.encode($0).get() }.flatMap { String(
                    data: $0,
                    encoding: .utf8
                ) },
                "member_custom_include": memberCustomInclude
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getReactions(
        id: String,
        limit: Int?,
        offset: Int?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<MessageReactionsPayload> {
        return .init(
            path: .getReactions(id: id),
            method: .get,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "limit": limit,
                "offset": offset
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getUserGroup(id: String, teamId: String?, requiresConnectionId: Bool = false) -> Endpoint<UserGroupResponse> {
        return .init(
            path: .getUserGroup(id: id),
            method: .get,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "team_id": teamId
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getUserLiveLocations(requiresConnectionId: Bool = false) -> Endpoint<SharedLocationsResponse> {
        return .init(
            path: .getUserLiveLocations,
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func hideChannel(
        type: String,
        id: String,
        hideChannelRequest: HideChannelRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<EmptyResponse> {
        return .init(
            path: .hideChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: hideChannelRequest
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

    static func listUserGroups(
        limit: Int?,
        idGt: String?,
        createdAtGt: String?,
        teamId: String?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<ListUserGroupsResponse> {
        return .init(
            path: .listUserGroups,
            method: .get,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "limit": limit,
                "id_gt": idGt,
                "created_at_gt": createdAtGt,
                "team_id": teamId
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func markDelivered(
        markDeliveredRequest: ChannelDeliveredRequestPayload,
        requiresConnectionId: Bool = false
    ) -> Endpoint<EmptyResponse> {
        return .init(
            path: .markDelivered,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: markDeliveredRequest
        )
    }

    static func mute(muteRequest: MuteRequest, requiresConnectionId: Bool = false) -> Endpoint<MuteResponse> {
        return .init(
            path: .mute,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: muteRequest
        )
    }

    static func muteChannel(
        muteChannelRequest: MuteChannelRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<MutedChannelPayloadResponse> {
        return .init(
            path: .muteChannel,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: muteChannelRequest
        )
    }

    static func queryDrafts(
        queryDraftsRequest: QueryDraftsRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<QueryDraftsResponse> {
        return .init(
            path: .queryDrafts,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: queryDraftsRequest
        )
    }

    static func queryMembers(payload: QueryMembersPayload?, requiresConnectionId: Bool = false) -> Endpoint<MembersResponse> {
        return .init(
            path: .queryMembers,
            method: .get,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "payload": payload.flatMap { try? CodableHelper.encode($0).get() }.flatMap { String(
                    data: $0,
                    encoding: .utf8
                ) }
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func queryPollVotes(
        pollId: String,
        queryPollVotesRequest: QueryPollVotesRequestBody,
        requiresConnectionId: Bool = false
    ) -> Endpoint<PollVoteListResponse> {
        return .init(
            path: .queryPollVotes(pollId: pollId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: queryPollVotesRequest
        )
    }

    static func queryReactions(
        id: String,
        queryReactionsRequest: QueryReactionsRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<MessageReactionsPayload> {
        return .init(
            path: .queryReactions(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: queryReactionsRequest
        )
    }

    static func queryReminders(
        queryRemindersRequest: QueryRemindersRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<QueryRemindersResponse> {
        return .init(
            path: .queryReminders,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: queryRemindersRequest
        )
    }

    static func queryUsers(payload: QueryUsersPayload?, requiresConnectionId: Bool = false) -> Endpoint<QueryUsersResponse> {
        return .init(
            path: .queryUsers,
            method: .get,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "payload": payload.flatMap { try? CodableHelper.encode($0).get() }.flatMap { String(
                    data: $0,
                    encoding: .utf8
                ) }
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func removeUserGroupMembers(
        id: String,
        removeUserGroupMembersRequest: RemoveUserGroupMembersRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UserGroupResponse> {
        return .init(
            path: .removeUserGroupMembers(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: removeUserGroupMembersRequest
        )
    }

    static func runMessageAction(
        id: String,
        messageActionRequest: MessageActionRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<MessageActionResponse> {
        return .init(
            path: .runMessageAction(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: messageActionRequest
        )
    }

    static func searchRoles(
        query: String,
        limit: Int?,
        nameGt: String?,
        roleType: String?,
        includeGlobalRoles: Bool?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<SearchRolesResponse> {
        return .init(
            path: .searchRoles,
            method: .get,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "query": query,
                "limit": limit,
                "name_gt": nameGt,
                "role_type": roleType,
                "include_global_roles": includeGlobalRoles
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func searchUserGroups(
        query: String,
        limit: Int?,
        nameGt: String?,
        idGt: String?,
        teamId: String?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<ListUserGroupsResponse> {
        return .init(
            path: .searchUserGroups,
            method: .get,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "query": query,
                "limit": limit,
                "name_gt": nameGt,
                "id_gt": idGt,
                "team_id": teamId
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func sendMessage(
        type: String,
        id: String,
        sendMessageRequest: SendMessageRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<SendMessageResponsePayload> {
        return .init(
            path: .sendMessage(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: sendMessageRequest
        )
    }

    static func sendReaction(
        id: String,
        sendReactionRequest: SendReactionRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<SendReactionResponse> {
        return .init(
            path: .sendReaction(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: sendReactionRequest
        )
    }

    static func showChannel(type: String, id: String, requiresConnectionId: Bool = false) -> Endpoint<EmptyResponse> {
        return .init(
            path: .showChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func stopWatchingChannel(type: String, id: String, requiresConnectionId: Bool = true) -> Endpoint<EmptyResponse> {
        return .init(
            path: .stopWatchingChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func translateMessage(
        id: String,
        translateMessageRequest: TranslateMessageRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<TranslateMessageResponse> {
        return .init(
            path: .translateMessage(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: translateMessageRequest
        )
    }

    static func truncateChannel(
        type: String,
        id: String,
        truncateChannelRequest: TruncateChannelRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<TruncateChannelResponse> {
        return .init(
            path: .truncateChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: truncateChannelRequest
        )
    }

    static func unban(targetUserId: String, channelCid: String?, requiresConnectionId: Bool = false) -> Endpoint<EmptyResponse> {
        return .init(
            path: .unban,
            method: .post,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "target_user_id": targetUserId,
                "channel_cid": channelCid
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func unblockUsers(
        unblockUsersRequest: UnblockUsersRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UnblockUsersResponse> {
        return .init(
            path: .unblockUsers,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: unblockUsersRequest
        )
    }

    static func unmute(unmuteRequest: UnmuteRequest, requiresConnectionId: Bool = false) -> Endpoint<UnmuteUsersResponse> {
        return .init(
            path: .unmute,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: unmuteRequest
        )
    }

    static func unmuteChannel(
        unmuteChannelRequest: UnmuteChannelRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UnmuteUsersResponse> {
        return .init(
            path: .unmuteChannel,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: unmuteChannelRequest
        )
    }

    static func unreadCounts(requiresConnectionId: Bool = false) -> Endpoint<CurrentUserUnreads> {
        return .init(
            path: .unreadCounts,
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func updateLiveLocation(
        updateLiveLocationRequest: UpdateLiveLocationRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<SharedLocation> {
        return .init(
            path: .updateLiveLocation,
            method: .put,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateLiveLocationRequest
        )
    }

    static func updateMemberPartial(
        type: String,
        id: String,
        updateMemberPartialRequest: UpdateMemberPartialRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UpdateMemberPartialResponse> {
        return .init(
            path: .updateMemberPartial(type: type, id: id),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateMemberPartialRequest
        )
    }

    static func updateMessage(
        id: String,
        updateMessageRequest: UpdateMessageRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UpdateMessageResponse> {
        return .init(
            path: .updateMessage(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateMessageRequest
        )
    }

    static func updateMessagePartial(
        id: String,
        updateMessagePartialRequest: UpdateMessagePartialRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UpdateMessagePartialResponse> {
        return .init(
            path: .updateMessagePartial(id: id),
            method: .put,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateMessagePartialRequest
        )
    }

    static func updatePollPartial(
        pollId: String,
        updatePollPartialRequest: UpdatePollPartialRequestBody,
        requiresConnectionId: Bool = false
    ) -> Endpoint<PollPayloadResponse> {
        return .init(
            path: .updatePollPartial(pollId: pollId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updatePollPartialRequest
        )
    }

    static func updatePushNotificationPreferences(
        upsertPushPreferencesRequest: UpsertPushPreferencesRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UpsertPushPreferencesResponse> {
        return .init(
            path: .updatePushNotificationPreferences,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: upsertPushPreferencesRequest
        )
    }

    static func updateReminder(
        messageId: String,
        updateReminderRequest: UpdateReminderRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UpdateReminderResponse> {
        return .init(
            path: .updateReminder(messageId: messageId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateReminderRequest
        )
    }

    static func updateUserGroup(
        id: String,
        updateUserGroupRequest: UpdateUserGroupRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UserGroupResponse> {
        return .init(
            path: .updateUserGroup(id: id),
            method: .put,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateUserGroupRequest
        )
    }

    static func updateUsersPartial(
        updateUsersPartialRequest: UpdateUsersPartialRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UpdateUsersResponse> {
        return .init(
            path: .updateUsersPartial,
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateUsersPartialRequest
        )
    }

    static func uploadChannelFile(
        type: String,
        id: String,
        multipartFormData: MultipartFormData,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UploadChannelFileResponse> {
        return .init(
            path: .uploadChannelFile(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: multipartFormData
        )
    }

    static func uploadChannelImage(
        type: String,
        id: String,
        multipartFormData: MultipartFormData,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UploadChannelResponse> {
        return .init(
            path: .uploadChannelImage(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: multipartFormData
        )
    }

    static func uploadFile(multipartFormData: MultipartFormData, requiresConnectionId: Bool = false) -> Endpoint<FileUploadResponse> {
        return .init(
            path: .uploadFile,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: multipartFormData
        )
    }

    static func uploadImage(multipartFormData: MultipartFormData, requiresConnectionId: Bool = false) -> Endpoint<ImageUploadResponse> {
        return .init(
            path: .uploadImage,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: multipartFormData
        )
    }
}
