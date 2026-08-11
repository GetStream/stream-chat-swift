//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum EndpointPath: Codable {
    case custom(String)
    case connect
    case sync
    case users
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
    case deleteChannel(String)
    case channelUpdate(String)
    case muteChannel(Bool)
    case showChannel(
        String,
        Bool
    )
    case truncateChannel(String)
    case markChannelRead(String)
    case markChannelUnread(String)
    case markAllChannelsRead
    case channelEvent(String)
    case pinnedMessages(String)

    case sendMessage(ChannelId)
    case message(MessageId)
    case editMessage(MessageId)
    case deleteMessage(MessageId)
    case pinMessage(MessageId)
    case unpinMessage(MessageId)
    case replies(MessageId)
    case reactions(MessageId)
    case addReaction(MessageId)
    case deleteReaction(
        MessageId,
        MessageReactionType
    )
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

    case addUserGroupMembers(id: String)
    case blockUsers
    case castPollVote(
        messageId: String,
        pollId: String
    )
    case createDevice
    case createPoll
    case createPollOption(pollId: String)
    case createUserGroup
    case deleteChannelFile(
        type: String,
        id: String
    )
    case deleteChannelImage(
        type: String,
        id: String
    )
    case deleteDevice
    case deleteFile
    case deleteImage
    case deletePoll(pollId: String)
    case deletePollVote(
        messageId: String,
        pollId: String,
        voteId: String
    )
    case deleteUserGroup(id: String)
    case getApp
    case getBlockedUsers
    case getOG
    case getUserGroup(id: String)
    case getUserLiveLocations
    case listDevices
    case listUserGroups
    case markDelivered
    case queryMembers
    case queryPollVotes(pollId: String)
    case removeUserGroupMembers(id: String)
    case searchRoles
    case searchUserGroups
    case stopWatchingChannel(
        type: String,
        id: String
    )
    case unblockUsers
    case unreadCounts
    case updateLiveLocation
    case updateMemberPartial(
        type: String,
        id: String
    )
    case updatePollPartial(pollId: String)
    case updatePushNotificationPreferences
    case updateUserGroup(id: String)
    case uploadChannelFile(
        type: String,
        id: String
    )
    case uploadChannelImage(
        type: String,
        id: String
    )
    case uploadFile
    case uploadImage

    var value: String {
        switch self {
        case let .custom(path): return path
        case .connect: return "connect"
        case .sync: return "sync"
        case .users: return "users"
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
        case let .deleteChannel(payloadPath): return "channels/\(payloadPath)"
        case let .channelUpdate(payloadPath): return "channels/\(payloadPath)"
        case let .muteChannel(mute): return "moderation/\(mute ? "mute" : "unmute")/channel"
        case let .showChannel(
            channelId,
            show
        ): return "channels/\(channelId)/\(show ? "show" : "hide")"
        case let .truncateChannel(channelId): return "channels/\(channelId)/truncate"
        case let .markChannelRead(channelId): return "channels/\(channelId)/read"
        case let .markChannelUnread(channelId): return "channels/\(channelId)/unread"
        case .markAllChannelsRead: return "channels/read"
        case let .channelEvent(channelId): return "channels/\(channelId)/event"
        case let .pinnedMessages(channelId): return "channels/\(channelId)/pinned_messages"

        case let .sendMessage(channelId): return "channels/\(channelId.apiPath)/message"
        case let .message(messageId): return "messages/\(messageId)"
        case let .editMessage(messageId): return "messages/\(messageId)"
        case let .deleteMessage(messageId): return "messages/\(messageId)"
        case let .pinMessage(messageId): return "messages/\(messageId)"
        case let .unpinMessage(messageId): return "messages/\(messageId)"
        case let .replies(messageId): return "messages/\(messageId)/replies"
        case let .reactions(messageId): return "messages/\(messageId)/reactions"
        case let .addReaction(messageId): return "messages/\(messageId)/reaction"
        case let .deleteReaction(
            messageId,
            reaction
        ): return "messages/\(messageId)/reaction/\(reaction.rawValue)"
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

        case let .addUserGroupMembers(id: id):
            return "/api/v2/usergroups/\(APIHelper.escapedPathItem(id))/members"
        case .blockUsers:
            return "/api/v2/users/block"
        case let .castPollVote(
            messageId: messageId,
            pollId: pollId
        ):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(messageId))/polls/\(APIHelper.escapedPathItem(pollId))/vote"
        case .createDevice:
            return "/api/v2/devices"
        case .createPoll:
            return "/api/v2/polls"
        case let .createPollOption(pollId: pollId):
            return "/api/v2/polls/\(APIHelper.escapedPathItem(pollId))/options"
        case .createUserGroup:
            return "/api/v2/usergroups"
        case let .deleteChannelFile(
            type: type,
            id: id
        ):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/file"
        case let .deleteChannelImage(
            type: type,
            id: id
        ):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/image"
        case .deleteDevice:
            return "/api/v2/devices"
        case .deleteFile:
            return "/api/v2/uploads/file"
        case .deleteImage:
            return "/api/v2/uploads/image"
        case let .deletePoll(pollId: pollId):
            return "/api/v2/polls/\(APIHelper.escapedPathItem(pollId))"
        case let .deletePollVote(
            messageId: messageId,
            pollId: pollId,
            voteId: voteId
        ):
            return "/api/v2/chat/messages/\(APIHelper.escapedPathItem(messageId))/polls/\(APIHelper.escapedPathItem(pollId))/vote/\(APIHelper.escapedPathItem(voteId))"
        case let .deleteUserGroup(id: id):
            return "/api/v2/usergroups/\(APIHelper.escapedPathItem(id))"
        case .getApp:
            return "/api/v2/app"
        case .getBlockedUsers:
            return "/api/v2/users/block"
        case .getOG:
            return "/api/v2/og"
        case let .getUserGroup(id: id):
            return "/api/v2/usergroups/\(APIHelper.escapedPathItem(id))"
        case .getUserLiveLocations:
            return "/api/v2/users/live_locations"
        case .listDevices:
            return "/api/v2/devices"
        case .listUserGroups:
            return "/api/v2/usergroups"
        case .markDelivered:
            return "/api/v2/chat/channels/delivered"
        case .queryMembers:
            return "/api/v2/chat/members"
        case let .queryPollVotes(pollId: pollId):
            return "/api/v2/polls/\(APIHelper.escapedPathItem(pollId))/votes"
        case let .removeUserGroupMembers(id: id):
            return "/api/v2/usergroups/\(APIHelper.escapedPathItem(id))/members/delete"
        case .searchRoles:
            return "/api/v2/roles/search"
        case .searchUserGroups:
            return "/api/v2/usergroups/search"
        case let .stopWatchingChannel(
            type: type,
            id: id
        ):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/stop-watching"
        case .unblockUsers:
            return "/api/v2/users/unblock"
        case .unreadCounts:
            return "/api/v2/chat/unread"
        case .updateLiveLocation:
            return "/api/v2/users/live_locations"
        case let .updateMemberPartial(
            type: type,
            id: id
        ):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/member"
        case let .updatePollPartial(pollId: pollId):
            return "/api/v2/polls/\(APIHelper.escapedPathItem(pollId))"
        case .updatePushNotificationPreferences:
            return "/api/v2/push_preferences"
        case let .updateUserGroup(id: id):
            return "/api/v2/usergroups/\(APIHelper.escapedPathItem(id))"
        case let .uploadChannelFile(
            type: type,
            id: id
        ):
            return "/api/v2/chat/channels/\(APIHelper.escapedPathItem(type))/\(APIHelper.escapedPathItem(id))/file"
        case let .uploadChannelImage(
            type: type,
            id: id
        ):
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
        path = try container.decode(
            EndpointPath.self,
            forKey: .path
        )
        method = try container.decode(
            EndpointMethod.self,
            forKey: .method
        )
        queryItems = try container.decodeIfPresent(
            Data.self,
            forKey: .queryItems
        )
        requiresConnectionId = try container.decode(
            Bool.self,
            forKey: .requiresConnectionId
        )
        requiresToken = try container.decode(
            Bool.self,
            forKey: .requiresToken
        )
        body = try container.decodeIfPresent(
            Data.self,
            forKey: .body
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(
            path,
            forKey: .path
        )
        try container.encode(
            method,
            forKey: .method
        )
        if let queryItems = try queryItems?.encodedAsData() {
            try container.encode(
                queryItems,
                forKey: .queryItems
            )
        }
        try container.encode(
            requiresConnectionId,
            forKey: .requiresConnectionId
        )
        try container.encode(
            requiresToken,
            forKey: .requiresToken
        )
        if let body = try body?.encodedAsData() {
            try container.encode(
                body,
                forKey: .body
            )
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

    static func blockUsers(
        blockUsersRequest: BlockUsersRequest,
        requiresConnectionId: Bool = false
    ) -> Endpoint<BlockUsersResponse> {
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
            path: .castPollVote(
                messageId: messageId,
                pollId: pollId
            ),
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

    static func deleteChannelFile(
        type: String,
        id: String,
        url: String?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<EmptyResponse> {
        return .init(
            path: .deleteChannelFile(
                type: type,
                id: id
            ),
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
            path: .deleteChannelImage(
                type: type,
                id: id
            ),
            method: .delete,
            queryItems: APIHelper.mapValuesToQueryDictionary([
                "url": url
            ]),
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteDevice(
        id: String,
        requiresConnectionId: Bool = false
    ) -> Endpoint<EmptyResponse> {
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

    static func deleteFile(
        url: String?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<EmptyResponse> {
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

    static func deleteImage(
        url: String?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<EmptyResponse> {
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

    static func deletePoll(
        pollId: String,
        requiresConnectionId: Bool = false
    ) -> Endpoint<EmptyResponse> {
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
            path: .deletePollVote(
                messageId: messageId,
                pollId: pollId,
                voteId: voteId
            ),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteUserGroup(
        id: String,
        teamId: String?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<EmptyResponse> {
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

    static func getOG(
        url: String,
        requiresConnectionId: Bool = false
    ) -> Endpoint<GetOGResponse> {
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

    static func getUserGroup(
        id: String,
        teamId: String?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UserGroupResponse> {
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

    static func queryMembers(
        payload: QueryMembersPayload?,
        requiresConnectionId: Bool = false
    ) -> Endpoint<MembersResponse> {
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

    static func stopWatchingChannel(
        type: String,
        id: String,
        requiresConnectionId: Bool = true
    ) -> Endpoint<EmptyResponse> {
        return .init(
            path: .stopWatchingChannel(
                type: type,
                id: id
            ),
            method: .post,
            queryItems: nil,
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
            path: .updateMemberPartial(
                type: type,
                id: id
            ),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateMemberPartialRequest
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

    static func uploadChannelFile(
        type: String,
        id: String,
        multipartFormData: MultipartFormData,
        requiresConnectionId: Bool = false
    ) -> Endpoint<UploadChannelFileResponse> {
        return .init(
            path: .uploadChannelFile(
                type: type,
                id: id
            ),
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
            path: .uploadChannelImage(
                type: type,
                id: id
            ),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: multipartFormData
        )
    }

    static func uploadFile(
        multipartFormData: MultipartFormData,
        requiresConnectionId: Bool = false
    ) -> Endpoint<FileUploadResponse> {
        return .init(
            path: .uploadFile,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: multipartFormData
        )
    }

    static func uploadImage(
        multipartFormData: MultipartFormData,
        requiresConnectionId: Bool = false
    ) -> Endpoint<ImageUploadResponse> {
        return .init(
            path: .uploadImage,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: multipartFormData
        )
    }
}
