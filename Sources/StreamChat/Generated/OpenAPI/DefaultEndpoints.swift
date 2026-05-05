//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DefaultEndpoint<ResponseType: Decodable>: Codable, Sendable {
    let path: DefaultEndpointPath
    let method: DefaultEndpointMethod
    let queryItems: [String: String?]?
    let requiresConnectionId: Bool
    let requiresToken: Bool
    let body: (Encodable & Sendable)?

    init(
        path: DefaultEndpointPath,
        method: DefaultEndpointMethod,
        queryItems: [String: String?]? = nil,
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
        path = try container.decode(DefaultEndpointPath.self, forKey: .path)
        method = try container.decode(DefaultEndpointMethod.self, forKey: .method)
        queryItems = try container.decodeIfPresent([String: String?].self, forKey: .queryItems)
        requiresConnectionId = try container.decode(Bool.self, forKey: .requiresConnectionId)
        requiresToken = try container.decode(Bool.self, forKey: .requiresToken)
        body = try container.decodeIfPresent(Data.self, forKey: .body)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        try container.encode(method, forKey: .method)
        try container.encodeIfPresent(queryItems, forKey: .queryItems)
        try container.encode(requiresConnectionId, forKey: .requiresConnectionId)
        try container.encode(requiresToken, forKey: .requiresToken)
        if let body = try body?.encodedAsData() {
            try container.encode(body, forKey: .body)
        }
    }
}

private extension Encodable where Self: Sendable {
    func encodedAsData() throws -> Data {
        try JSONEncoder.stream.encode(AnyEncodable(self))
    }
}

enum DefaultEndpointMethod: String, Codable, Equatable {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
    case put = "PUT"
}

enum DefaultEndpointPath: Codable, Equatable {
    case addUserGroupMembers(id: String)
    case appeal
    case ban
    case blockUsers
    case castPollVote(messageId: String, pollId: String)
    case createBlockList
    case createDevice
    case createDraft(type: String, id: String)
    case createGuest
    case createPoll
    case createPollOption(pollId: String)
    case createReminder(messageId: String)
    case createUserGroup
    case deleteBlockList(name: String)
    case deleteChannel(type: String, id: String)
    case deleteChannelFile(type: String, id: String)
    case deleteChannelImage(type: String, id: String)
    case deleteChannels
    case deleteConfig(key: String)
    case deleteDevice
    case deleteDraft(type: String, id: String)
    case deleteFile
    case deleteImage
    case deleteMessage(id: String)
    case deletePoll(pollId: String)
    case deletePollOption(pollId: String, optionId: String)
    case deletePollVote(messageId: String, pollId: String, voteId: String)
    case deleteReaction(id: String, type: String)
    case deleteReminder(messageId: String)
    case deleteUserGroup(id: String)
    case flag
    case getApp
    case getAppeal(id: String)
    case getBlockedUsers
    case getConfig(key: String)
    case getDraft(type: String, id: String)
    case getManyMessages(type: String, id: String)
    case getMessage(id: String)
    case getOG
    case getOrCreateChannel(type: String, id: String)
    case getOrCreateDistinctChannel(type: String)
    case getPoll(pollId: String)
    case getPollOption(pollId: String, optionId: String)
    case getReactions(id: String)
    case getReplies(parentId: String)
    case getThread(messageId: String)
    case getUserGroup(id: String)
    case getUserLiveLocations
    case groupedQueryChannels
    case hideChannel(type: String, id: String)
    case listBlockLists
    case listDevices
    case listUserGroups
    case longPoll
    case markChannelsRead
    case markDelivered
    case markRead(type: String, id: String)
    case markUnread(type: String, id: String)
    case mute
    case muteChannel
    case queryAppeals
    case queryBannedUsers
    case queryChannels
    case queryDrafts
    case queryFutureChannelBans
    case queryMembers
    case queryMessageFlags
    case queryModerationConfigs
    case queryPollVotes(pollId: String)
    case queryPolls
    case queryReactions(id: String)
    case queryReminders
    case queryReviewQueue
    case queryThreads
    case queryUsers
    case removeUserGroupMembers(id: String)
    case runMessageAction(id: String)
    case search
    case searchUserGroups
    case sendEvent(type: String, id: String)
    case sendMessage(type: String, id: String)
    case sendReaction(id: String)
    case showChannel(type: String, id: String)
    case stopWatchingChannel(type: String, id: String)
    case submitAction
    case sync
    case translateMessage(id: String)
    case truncateChannel(type: String, id: String)
    case unblockUsers
    case unmuteChannel
    case unreadCounts
    case updateBlockList(name: String)
    case updateChannel(type: String, id: String)
    case updateChannelPartial(type: String, id: String)
    case updateLiveLocation
    case updateMemberPartial(type: String, id: String)
    case updateMessage(id: String)
    case updateMessagePartial(id: String)
    case updatePoll
    case updatePollOption(pollId: String)
    case updatePollPartial(pollId: String)
    case updatePushNotificationPreferences
    case updateReminder(messageId: String)
    case updateThreadPartial(messageId: String)
    case updateUserGroup(id: String)
    case updateUsers
    case updateUsersPartial
    case uploadChannelFile(type: String, id: String)
    case uploadChannelImage(type: String, id: String)
    case uploadFile
    case uploadImage
    case upsertConfig

    var value: String {
        switch self {
        case let .addUserGroupMembers(id):
            return "/api/v2/usergroups/\(id)/members"
        case .appeal:
            return "/api/v2/moderation/appeal"
        case .ban:
            return "/api/v2/moderation/ban"
        case .blockUsers:
            return "/api/v2/users/block"
        case let .castPollVote(messageId, pollId):
            return "/api/v2/chat/messages/\(messageId)/polls/\(pollId)/vote"
        case .createBlockList:
            return "/api/v2/blocklists"
        case .createDevice:
            return "/api/v2/devices"
        case let .createDraft(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/draft"
        case .createGuest:
            return "/api/v2/guest"
        case .createPoll:
            return "/api/v2/polls"
        case let .createPollOption(pollId):
            return "/api/v2/polls/\(pollId)/options"
        case let .createReminder(messageId):
            return "/api/v2/chat/messages/\(messageId)/reminders"
        case .createUserGroup:
            return "/api/v2/usergroups"
        case let .deleteBlockList(name):
            return "/api/v2/blocklists/\(name)"
        case let .deleteChannel(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)"
        case let .deleteChannelFile(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/file"
        case let .deleteChannelImage(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/image"
        case .deleteChannels:
            return "/api/v2/chat/channels/delete"
        case let .deleteConfig(key):
            return "/api/v2/moderation/config/\(key)"
        case .deleteDevice:
            return "/api/v2/devices"
        case let .deleteDraft(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/draft"
        case .deleteFile:
            return "/api/v2/uploads/file"
        case .deleteImage:
            return "/api/v2/uploads/image"
        case let .deleteMessage(id):
            return "/api/v2/chat/messages/\(id)"
        case let .deletePoll(pollId):
            return "/api/v2/polls/\(pollId)"
        case let .deletePollOption(pollId, optionId):
            return "/api/v2/polls/\(pollId)/options/\(optionId)"
        case let .deletePollVote(messageId, pollId, voteId):
            return "/api/v2/chat/messages/\(messageId)/polls/\(pollId)/vote/\(voteId)"
        case let .deleteReaction(id, type):
            return "/api/v2/chat/messages/\(id)/reaction/\(type)"
        case let .deleteReminder(messageId):
            return "/api/v2/chat/messages/\(messageId)/reminders"
        case let .deleteUserGroup(id):
            return "/api/v2/usergroups/\(id)"
        case .flag:
            return "/api/v2/moderation/flag"
        case .getApp:
            return "/api/v2/app"
        case let .getAppeal(id):
            return "/api/v2/moderation/appeal/\(id)"
        case .getBlockedUsers:
            return "/api/v2/users/block"
        case let .getConfig(key):
            return "/api/v2/moderation/config/\(key)"
        case let .getDraft(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/draft"
        case let .getManyMessages(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/messages"
        case let .getMessage(id):
            return "/api/v2/chat/messages/\(id)"
        case .getOG:
            return "/api/v2/og"
        case let .getOrCreateChannel(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/query"
        case let .getOrCreateDistinctChannel(type):
            return "/api/v2/chat/channels/\(type)/query"
        case let .getPoll(pollId):
            return "/api/v2/polls/\(pollId)"
        case let .getPollOption(pollId, optionId):
            return "/api/v2/polls/\(pollId)/options/\(optionId)"
        case let .getReactions(id):
            return "/api/v2/chat/messages/\(id)/reactions"
        case let .getReplies(parentId):
            return "/api/v2/chat/messages/\(parentId)/replies"
        case let .getThread(messageId):
            return "/api/v2/chat/threads/\(messageId)"
        case let .getUserGroup(id):
            return "/api/v2/usergroups/\(id)"
        case .getUserLiveLocations:
            return "/api/v2/users/live_locations"
        case .groupedQueryChannels:
            return "/api/v2/chat/channels/grouped"
        case let .hideChannel(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/hide"
        case .listBlockLists:
            return "/api/v2/blocklists"
        case .listDevices:
            return "/api/v2/devices"
        case .listUserGroups:
            return "/api/v2/usergroups"
        case .longPoll:
            return "/api/v2/longpoll"
        case .markChannelsRead:
            return "/api/v2/chat/channels/read"
        case .markDelivered:
            return "/api/v2/chat/channels/delivered"
        case let .markRead(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/read"
        case let .markUnread(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/unread"
        case .mute:
            return "/api/v2/moderation/mute"
        case .muteChannel:
            return "/api/v2/chat/moderation/mute/channel"
        case .queryAppeals:
            return "/api/v2/moderation/appeals"
        case .queryBannedUsers:
            return "/api/v2/chat/query_banned_users"
        case .queryChannels:
            return "/api/v2/chat/channels"
        case .queryDrafts:
            return "/api/v2/chat/drafts/query"
        case .queryFutureChannelBans:
            return "/api/v2/chat/query_future_channel_bans"
        case .queryMembers:
            return "/api/v2/chat/members"
        case .queryMessageFlags:
            return "/api/v2/chat/moderation/flags/message"
        case .queryModerationConfigs:
            return "/api/v2/moderation/configs"
        case let .queryPollVotes(pollId):
            return "/api/v2/polls/\(pollId)/votes"
        case .queryPolls:
            return "/api/v2/polls/query"
        case let .queryReactions(id):
            return "/api/v2/chat/messages/\(id)/reactions"
        case .queryReminders:
            return "/api/v2/chat/reminders/query"
        case .queryReviewQueue:
            return "/api/v2/moderation/review_queue"
        case .queryThreads:
            return "/api/v2/chat/threads"
        case .queryUsers:
            return "/api/v2/users"
        case let .removeUserGroupMembers(id):
            return "/api/v2/usergroups/\(id)/members/delete"
        case let .runMessageAction(id):
            return "/api/v2/chat/messages/\(id)/action"
        case .search:
            return "/api/v2/chat/search"
        case .searchUserGroups:
            return "/api/v2/usergroups/search"
        case let .sendEvent(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/event"
        case let .sendMessage(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/message"
        case let .sendReaction(id):
            return "/api/v2/chat/messages/\(id)/reaction"
        case let .showChannel(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/show"
        case let .stopWatchingChannel(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/stop-watching"
        case .submitAction:
            return "/api/v2/moderation/submit_action"
        case .sync:
            return "/api/v2/chat/sync"
        case let .translateMessage(id):
            return "/api/v2/chat/messages/\(id)/translate"
        case let .truncateChannel(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/truncate"
        case .unblockUsers:
            return "/api/v2/users/unblock"
        case .unmuteChannel:
            return "/api/v2/chat/moderation/unmute/channel"
        case .unreadCounts:
            return "/api/v2/chat/unread"
        case let .updateBlockList(name):
            return "/api/v2/blocklists/\(name)"
        case let .updateChannel(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)"
        case let .updateChannelPartial(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)"
        case .updateLiveLocation:
            return "/api/v2/users/live_locations"
        case let .updateMemberPartial(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/member"
        case let .updateMessage(id):
            return "/api/v2/chat/messages/\(id)"
        case let .updateMessagePartial(id):
            return "/api/v2/chat/messages/\(id)"
        case .updatePoll:
            return "/api/v2/polls"
        case let .updatePollOption(pollId):
            return "/api/v2/polls/\(pollId)/options"
        case let .updatePollPartial(pollId):
            return "/api/v2/polls/\(pollId)"
        case .updatePushNotificationPreferences:
            return "/api/v2/push_preferences"
        case let .updateReminder(messageId):
            return "/api/v2/chat/messages/\(messageId)/reminders"
        case let .updateThreadPartial(messageId):
            return "/api/v2/chat/threads/\(messageId)"
        case let .updateUserGroup(id):
            return "/api/v2/usergroups/\(id)"
        case .updateUsers:
            return "/api/v2/users"
        case .updateUsersPartial:
            return "/api/v2/users"
        case let .uploadChannelFile(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/file"
        case let .uploadChannelImage(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/image"
        case .uploadFile:
            return "/api/v2/uploads/file"
        case .uploadImage:
            return "/api/v2/uploads/image"
        case .upsertConfig:
            return "/api/v2/moderation/config"
        }
    }
}

extension DefaultEndpoint {
    static func addUserGroupMembers(id: String, addUserGroupMembersRequest: AddUserGroupMembersRequest) -> DefaultEndpoint<AddUserGroupMembersResponse> {
        .init(
            path: .addUserGroupMembers(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: addUserGroupMembersRequest
        )
    }

    static func appeal(appealRequest: AppealRequest) -> DefaultEndpoint<AppealResponse> {
        .init(
            path: .appeal,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: appealRequest
        )
    }

    static func ban(banRequest: BanRequest) -> DefaultEndpoint<BanResponse> {
        .init(
            path: .ban,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: banRequest
        )
    }

    static func blockUsers(blockUsersRequest: BlockUsersRequest) -> DefaultEndpoint<BlockUsersResponse> {
        .init(
            path: .blockUsers,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: blockUsersRequest
        )
    }

    static func castPollVote(messageId: String, pollId: String, castPollVoteRequest: CastPollVoteRequest) -> DefaultEndpoint<PollVoteResponse> {
        .init(
            path: .castPollVote(messageId: messageId, pollId: pollId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: castPollVoteRequest
        )
    }

    static func createBlockList(createBlockListRequest: CreateBlockListRequest) -> DefaultEndpoint<CreateBlockListResponse> {
        .init(
            path: .createBlockList,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createBlockListRequest
        )
    }

    static func createDevice(createDeviceRequest: CreateDeviceRequest) -> DefaultEndpoint<Response> {
        .init(
            path: .createDevice,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createDeviceRequest
        )
    }

    static func createDraft(type: String, id: String, createDraftRequest: CreateDraftRequest) -> DefaultEndpoint<CreateDraftResponse> {
        .init(
            path: .createDraft(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createDraftRequest
        )
    }

    static func createGuest(createGuestRequest: CreateGuestRequest) -> DefaultEndpoint<CreateGuestResponse> {
        .init(
            path: .createGuest,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: false,
            body: createGuestRequest
        )
    }

    static func createPoll(createPollRequest: CreatePollRequest) -> DefaultEndpoint<PollResponse> {
        .init(
            path: .createPoll,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createPollRequest
        )
    }

    static func createPollOption(pollId: String, createPollOptionRequest: CreatePollOptionRequest) -> DefaultEndpoint<PollOptionResponseOpenAPI> {
        .init(
            path: .createPollOption(pollId: pollId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createPollOptionRequest
        )
    }

    static func createReminder(messageId: String, createReminderRequest: CreateReminderRequest) -> DefaultEndpoint<ReminderResponseData> {
        .init(
            path: .createReminder(messageId: messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createReminderRequest
        )
    }

    static func createUserGroup(createUserGroupRequest: CreateUserGroupRequest) -> DefaultEndpoint<CreateUserGroupResponse> {
        .init(
            path: .createUserGroup,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createUserGroupRequest
        )
    }

    static func deleteBlockList(name: String, team: String?) -> DefaultEndpoint<Response> {
        .init(
            path: .deleteBlockList(name: name),
            method: .delete,
            queryItems: [
                "team": APIHelper.convertAnyToString(team)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteChannel(type: String, id: String, hardDelete: Bool?) -> DefaultEndpoint<DeleteChannelResponse> {
        .init(
            path: .deleteChannel(type: type, id: id),
            method: .delete,
            queryItems: [
                "hard_delete": APIHelper.convertAnyToString(hardDelete)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteChannelFile(type: String, id: String, url: String?) -> DefaultEndpoint<Response> {
        .init(
            path: .deleteChannelFile(type: type, id: id),
            method: .delete,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteChannelImage(type: String, id: String, url: String?) -> DefaultEndpoint<Response> {
        .init(
            path: .deleteChannelImage(type: type, id: id),
            method: .delete,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteChannels(deleteChannelsRequest: DeleteChannelsRequest) -> DefaultEndpoint<DeleteChannelsResponse> {
        .init(
            path: .deleteChannels,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: deleteChannelsRequest
        )
    }

    static func deleteConfig(key: String, team: String?) -> DefaultEndpoint<DeleteModerationConfigResponse> {
        .init(
            path: .deleteConfig(key: key),
            method: .delete,
            queryItems: [
                "team": APIHelper.convertAnyToString(team)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteDevice(id: String) -> DefaultEndpoint<Response> {
        .init(
            path: .deleteDevice,
            method: .delete,
            queryItems: [
                "id": APIHelper.convertAnyToString(id)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteDraft(type: String, id: String, parentId: String?) -> DefaultEndpoint<Response> {
        .init(
            path: .deleteDraft(type: type, id: id),
            method: .delete,
            queryItems: [
                "parent_id": APIHelper.convertAnyToString(parentId)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteFile(url: String?) -> DefaultEndpoint<Response> {
        .init(
            path: .deleteFile,
            method: .delete,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteImage(url: String?) -> DefaultEndpoint<Response> {
        .init(
            path: .deleteImage,
            method: .delete,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteMessage(id: String, hard: Bool?, deletedBy: String?, deleteForMe: Bool?) -> DefaultEndpoint<DeleteMessageResponse> {
        .init(
            path: .deleteMessage(id: id),
            method: .delete,
            queryItems: [
                "hard": APIHelper.convertAnyToString(hard),
                "deleted_by": APIHelper.convertAnyToString(deletedBy),
                "delete_for_me": APIHelper.convertAnyToString(deleteForMe)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deletePoll(pollId: String, userId: String?) -> DefaultEndpoint<Response> {
        .init(
            path: .deletePoll(pollId: pollId),
            method: .delete,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deletePollOption(pollId: String, optionId: String, userId: String?) -> DefaultEndpoint<Response> {
        .init(
            path: .deletePollOption(pollId: pollId, optionId: optionId),
            method: .delete,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deletePollVote(messageId: String, pollId: String, voteId: String, userId: String?) -> DefaultEndpoint<PollVoteResponse> {
        .init(
            path: .deletePollVote(messageId: messageId, pollId: pollId, voteId: voteId),
            method: .delete,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteReaction(id: String, type: String, userId: String?) -> DefaultEndpoint<DeleteReactionResponse> {
        .init(
            path: .deleteReaction(id: id, type: type),
            method: .delete,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteReminder(messageId: String) -> DefaultEndpoint<DeleteReminderResponse> {
        .init(
            path: .deleteReminder(messageId: messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteUserGroup(id: String, teamId: String?) -> DefaultEndpoint<Response> {
        .init(
            path: .deleteUserGroup(id: id),
            method: .delete,
            queryItems: [
                "team_id": APIHelper.convertAnyToString(teamId)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func flag(flagRequest: FlagRequest) -> DefaultEndpoint<FlagResponse> {
        .init(
            path: .flag,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: flagRequest
        )
    }

    static func getApp() -> DefaultEndpoint<GetApplicationResponse> {
        .init(
            path: .getApp,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getAppeal(id: String) -> DefaultEndpoint<GetAppealResponse> {
        .init(
            path: .getAppeal(id: id),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getBlockedUsers() -> DefaultEndpoint<GetBlockedUsersResponse> {
        .init(
            path: .getBlockedUsers,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getConfig(key: String, team: String?) -> DefaultEndpoint<GetConfigResponse> {
        .init(
            path: .getConfig(key: key),
            method: .get,
            queryItems: [
                "team": APIHelper.convertAnyToString(team)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getDraft(type: String, id: String, parentId: String?) -> DefaultEndpoint<GetDraftResponse> {
        .init(
            path: .getDraft(type: type, id: id),
            method: .get,
            queryItems: [
                "parent_id": APIHelper.convertAnyToString(parentId)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getManyMessages(type: String, id: String, ids: [String]) -> DefaultEndpoint<GetManyMessagesResponse> {
        .init(
            path: .getManyMessages(type: type, id: id),
            method: .get,
            queryItems: [
                "ids": ids.joined(separator: ",")
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getMessage(id: String) -> DefaultEndpoint<GetMessageResponse> {
        .init(
            path: .getMessage(id: id),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getOG(url: String) -> DefaultEndpoint<GetOGResponse> {
        .init(
            path: .getOG,
            method: .get,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getOrCreateChannel(type: String, id: String, channelGetOrCreateRequest: ChannelGetOrCreateRequest) -> DefaultEndpoint<ChannelStateResponse> {
        .init(
            path: .getOrCreateChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: channelGetOrCreateRequest
        )
    }

    static func getOrCreateDistinctChannel(type: String, channelGetOrCreateRequest: ChannelGetOrCreateRequest) -> DefaultEndpoint<ChannelStateResponse> {
        .init(
            path: .getOrCreateDistinctChannel(type: type),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: channelGetOrCreateRequest
        )
    }

    static func getPoll(pollId: String, userId: String?) -> DefaultEndpoint<PollResponse> {
        .init(
            path: .getPoll(pollId: pollId),
            method: .get,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getPollOption(pollId: String, optionId: String, userId: String?) -> DefaultEndpoint<PollOptionResponseOpenAPI> {
        .init(
            path: .getPollOption(pollId: pollId, optionId: optionId),
            method: .get,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getReactions(id: String, limit: Int?, offset: Int?) -> DefaultEndpoint<GetReactionsResponse> {
        .init(
            path: .getReactions(id: id),
            method: .get,
            queryItems: [
                "limit": APIHelper.convertAnyToString(limit),
                "offset": APIHelper.convertAnyToString(offset)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getReplies(parentId: String, limit: Int?, idGte: String?, idGt: String?, idLte: String?, idLt: String?, idAround: String?, sort: [SortParamRequestOpenAPI]?) -> DefaultEndpoint<GetRepliesResponse> {
        .init(
            path: .getReplies(parentId: parentId),
            method: .get,
            queryItems: [
                "limit": APIHelper.convertAnyToString(limit),
                "id_gte": APIHelper.convertAnyToString(idGte),
                "id_gt": APIHelper.convertAnyToString(idGt),
                "id_lte": APIHelper.convertAnyToString(idLte),
                "id_lt": APIHelper.convertAnyToString(idLt),
                "id_around": APIHelper.convertAnyToString(idAround),
                "sort": APIHelper.convertAnyToString(sort)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getThread(messageId: String, watch: Bool?, replyLimit: Int?, participantLimit: Int?, memberLimit: Int?) -> DefaultEndpoint<GetThreadResponse> {
        .init(
            path: .getThread(messageId: messageId),
            method: .get,
            queryItems: [
                "watch": APIHelper.convertAnyToString(watch),
                "reply_limit": APIHelper.convertAnyToString(replyLimit),
                "participant_limit": APIHelper.convertAnyToString(participantLimit),
                "member_limit": APIHelper.convertAnyToString(memberLimit)
            ],
            requiresConnectionId: true,
            body: nil
        )
    }

    static func getUserGroup(id: String, teamId: String?) -> DefaultEndpoint<GetUserGroupResponse> {
        .init(
            path: .getUserGroup(id: id),
            method: .get,
            queryItems: [
                "team_id": APIHelper.convertAnyToString(teamId)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getUserLiveLocations() -> DefaultEndpoint<SharedLocationsResponse> {
        .init(
            path: .getUserLiveLocations,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func groupedQueryChannels(groupedQueryChannelsRequest: GroupedQueryChannelsRequest) -> DefaultEndpoint<GroupedQueryChannelsResponse> {
        .init(
            path: .groupedQueryChannels,
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: groupedQueryChannelsRequest
        )
    }

    static func hideChannel(type: String, id: String, hideChannelRequest: HideChannelRequest) -> DefaultEndpoint<HideChannelResponse> {
        .init(
            path: .hideChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: hideChannelRequest
        )
    }

    static func listBlockLists(team: String?) -> DefaultEndpoint<ListBlockListResponse> {
        .init(
            path: .listBlockLists,
            method: .get,
            queryItems: [
                "team": APIHelper.convertAnyToString(team)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func listDevices() -> DefaultEndpoint<ListDevicesResponse> {
        .init(
            path: .listDevices,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func listUserGroups(limit: Int?, idGt: String?, createdAtGt: String?, teamId: String?) -> DefaultEndpoint<ListUserGroupsResponse> {
        .init(
            path: .listUserGroups,
            method: .get,
            queryItems: [
                "limit": APIHelper.convertAnyToString(limit),
                "id_gt": APIHelper.convertAnyToString(idGt),
                "created_at_gt": APIHelper.convertAnyToString(createdAtGt),
                "team_id": APIHelper.convertAnyToString(teamId)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func longPoll(json: WSAuthMessage?) -> DefaultEndpoint<EmptyResponse> {
        .init(
            path: .longPoll,
            method: .get,
            queryItems: [
                "json": APIHelper.convertAnyToString(json)
            ],
            requiresConnectionId: true,
            body: nil
        )
    }

    static func markChannelsRead(markChannelsReadRequest: MarkChannelsReadRequest) -> DefaultEndpoint<MarkReadResponse> {
        .init(
            path: .markChannelsRead,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: markChannelsReadRequest
        )
    }

    static func markDelivered(markDeliveredRequest: MarkDeliveredRequest) -> DefaultEndpoint<MarkDeliveredResponse> {
        .init(
            path: .markDelivered,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: markDeliveredRequest
        )
    }

    static func markRead(type: String, id: String, markReadRequest: MarkReadRequest) -> DefaultEndpoint<MarkReadResponse> {
        .init(
            path: .markRead(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: markReadRequest
        )
    }

    static func markUnread(type: String, id: String, markUnreadRequest: MarkUnreadRequest) -> DefaultEndpoint<Response> {
        .init(
            path: .markUnread(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: markUnreadRequest
        )
    }

    static func mute(muteRequest: MuteRequest) -> DefaultEndpoint<MuteResponse> {
        .init(
            path: .mute,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: muteRequest
        )
    }

    static func muteChannel(muteChannelRequest: MuteChannelRequest) -> DefaultEndpoint<MuteChannelResponse> {
        .init(
            path: .muteChannel,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: muteChannelRequest
        )
    }

    static func queryAppeals(queryAppealsRequest: QueryAppealsRequest) -> DefaultEndpoint<QueryAppealsResponse> {
        .init(
            path: .queryAppeals,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: queryAppealsRequest
        )
    }

    static func queryBannedUsers(payload: QueryBannedUsersPayload?) -> DefaultEndpoint<QueryBannedUsersResponse> {
        .init(
            path: .queryBannedUsers,
            method: .get,
            queryItems: [
                "payload": APIHelper.convertAnyToString(payload)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func queryChannels(queryChannelsRequest: QueryChannelsRequest) -> DefaultEndpoint<QueryChannelsResponse> {
        .init(
            path: .queryChannels,
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: queryChannelsRequest
        )
    }

    static func queryDrafts(queryDraftsRequest: QueryDraftsRequest) -> DefaultEndpoint<QueryDraftsResponse> {
        .init(
            path: .queryDrafts,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: queryDraftsRequest
        )
    }

    static func queryFutureChannelBans(payload: QueryFutureChannelBansPayload?) -> DefaultEndpoint<QueryFutureChannelBansResponse> {
        .init(
            path: .queryFutureChannelBans,
            method: .get,
            queryItems: [
                "payload": APIHelper.convertAnyToString(payload)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func queryMembers(payload: QueryMembersPayload?) -> DefaultEndpoint<MembersResponse> {
        .init(
            path: .queryMembers,
            method: .get,
            queryItems: [
                "payload": APIHelper.convertAnyToString(payload)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func queryMessageFlags(payload: QueryMessageFlagsPayload?) -> DefaultEndpoint<QueryMessageFlagsResponse> {
        .init(
            path: .queryMessageFlags,
            method: .get,
            queryItems: [
                "payload": APIHelper.convertAnyToString(payload)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func queryModerationConfigs(queryModerationConfigsRequest: QueryModerationConfigsRequest) -> DefaultEndpoint<QueryModerationConfigsResponse> {
        .init(
            path: .queryModerationConfigs,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: queryModerationConfigsRequest
        )
    }

    static func queryPollVotes(pollId: String, userId: String?, queryPollVotesRequest: QueryPollVotesRequest) -> DefaultEndpoint<PollVotesResponse> {
        .init(
            path: .queryPollVotes(pollId: pollId),
            method: .post,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: false,
            body: queryPollVotesRequest
        )
    }

    static func queryPolls(userId: String?, queryPollsRequest: QueryPollsRequest) -> DefaultEndpoint<QueryPollsResponse> {
        .init(
            path: .queryPolls,
            method: .post,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: false,
            body: queryPollsRequest
        )
    }

    static func queryReactions(id: String, queryReactionsRequest: QueryReactionsRequest) -> DefaultEndpoint<QueryReactionsResponse> {
        .init(
            path: .queryReactions(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: queryReactionsRequest
        )
    }

    static func queryReminders(queryRemindersRequest: QueryRemindersRequest) -> DefaultEndpoint<QueryRemindersResponse> {
        .init(
            path: .queryReminders,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: queryRemindersRequest
        )
    }

    static func queryReviewQueue(queryReviewQueueRequest: QueryReviewQueueRequest) -> DefaultEndpoint<QueryReviewQueueResponse> {
        .init(
            path: .queryReviewQueue,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: queryReviewQueueRequest
        )
    }

    static func queryThreads(queryThreadsRequest: QueryThreadsRequest) -> DefaultEndpoint<QueryThreadsResponse> {
        .init(
            path: .queryThreads,
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: queryThreadsRequest
        )
    }

    static func queryUsers(payload: QueryUsersPayload?) -> DefaultEndpoint<QueryUsersResponse> {
        .init(
            path: .queryUsers,
            method: .get,
            queryItems: [
                "payload": APIHelper.convertAnyToString(payload)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func removeUserGroupMembers(id: String, removeUserGroupMembersRequest: RemoveUserGroupMembersRequest) -> DefaultEndpoint<RemoveUserGroupMembersResponse> {
        .init(
            path: .removeUserGroupMembers(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: removeUserGroupMembersRequest
        )
    }

    static func runMessageAction(id: String, messageActionRequest: MessageActionRequest) -> DefaultEndpoint<MessageActionResponse> {
        .init(
            path: .runMessageAction(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: messageActionRequest
        )
    }

    static func search(payload: SearchPayload?) -> DefaultEndpoint<SearchResponse> {
        .init(
            path: .search,
            method: .get,
            queryItems: [
                "payload": APIHelper.convertAnyToString(payload)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func searchUserGroups(query: String, limit: Int?, nameGt: String?, idGt: String?, teamId: String?) -> DefaultEndpoint<SearchUserGroupsResponse> {
        .init(
            path: .searchUserGroups,
            method: .get,
            queryItems: [
                "query": APIHelper.convertAnyToString(query),
                "limit": APIHelper.convertAnyToString(limit),
                "name_gt": APIHelper.convertAnyToString(nameGt),
                "id_gt": APIHelper.convertAnyToString(idGt),
                "team_id": APIHelper.convertAnyToString(teamId)
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func sendEvent(type: String, id: String, sendEventRequest: SendEventRequest) -> DefaultEndpoint<EventResponse> {
        .init(
            path: .sendEvent(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: sendEventRequest
        )
    }

    static func sendMessage(type: String, id: String, sendMessageRequest: SendMessageRequest) -> DefaultEndpoint<SendMessageResponseOpenAPI> {
        .init(
            path: .sendMessage(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: sendMessageRequest
        )
    }

    static func sendReaction(id: String, sendReactionRequest: SendReactionRequest) -> DefaultEndpoint<SendReactionResponse> {
        .init(
            path: .sendReaction(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: sendReactionRequest
        )
    }

    static func showChannel(type: String, id: String) -> DefaultEndpoint<ShowChannelResponse> {
        .init(
            path: .showChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func stopWatchingChannel(type: String, id: String) -> DefaultEndpoint<Response> {
        .init(
            path: .stopWatchingChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: nil
        )
    }

    static func submitAction(submitActionRequest: SubmitActionRequest) -> DefaultEndpoint<SubmitActionResponse> {
        .init(
            path: .submitAction,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: submitActionRequest
        )
    }

    static func sync(syncRequest: SyncRequest, withInaccessibleCids: Bool?, watch: Bool?) -> DefaultEndpoint<SyncResponse> {
        .init(
            path: .sync,
            method: .post,
            queryItems: [
                "with_inaccessible_cids": APIHelper.convertAnyToString(withInaccessibleCids),
                "watch": APIHelper.convertAnyToString(watch)
            ],
            requiresConnectionId: true,
            body: syncRequest
        )
    }

    static func translateMessage(id: String, translateMessageRequest: TranslateMessageRequest) -> DefaultEndpoint<MessageActionResponse> {
        .init(
            path: .translateMessage(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: translateMessageRequest
        )
    }

    static func truncateChannel(type: String, id: String, truncateChannelRequest: TruncateChannelRequest) -> DefaultEndpoint<TruncateChannelResponse> {
        .init(
            path: .truncateChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: truncateChannelRequest
        )
    }

    static func unblockUsers(unblockUsersRequest: UnblockUsersRequest) -> DefaultEndpoint<UnblockUsersResponse> {
        .init(
            path: .unblockUsers,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: unblockUsersRequest
        )
    }

    static func unmuteChannel(unmuteChannelRequest: UnmuteChannelRequest) -> DefaultEndpoint<UnmuteResponse> {
        .init(
            path: .unmuteChannel,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: unmuteChannelRequest
        )
    }

    static func unreadCounts() -> DefaultEndpoint<WrappedUnreadCountsResponse> {
        .init(
            path: .unreadCounts,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func updateBlockList(name: String, updateBlockListRequest: UpdateBlockListRequest) -> DefaultEndpoint<UpdateBlockListResponse> {
        .init(
            path: .updateBlockList(name: name),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateBlockListRequest
        )
    }

    static func updateChannel(type: String, id: String, updateChannelRequest: UpdateChannelRequest) -> DefaultEndpoint<UpdateChannelResponse> {
        .init(
            path: .updateChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateChannelRequest
        )
    }

    static func updateChannelPartial(type: String, id: String, updateChannelPartialRequest: UpdateChannelPartialRequest) -> DefaultEndpoint<UpdateChannelPartialResponse> {
        .init(
            path: .updateChannelPartial(type: type, id: id),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateChannelPartialRequest
        )
    }

    static func updateLiveLocation(updateLiveLocationRequest: UpdateLiveLocationRequest) -> DefaultEndpoint<SharedLocationResponse> {
        .init(
            path: .updateLiveLocation,
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateLiveLocationRequest
        )
    }

    static func updateMemberPartial(type: String, id: String, updateMemberPartialRequest: UpdateMemberPartialRequest) -> DefaultEndpoint<UpdateMemberPartialResponse> {
        .init(
            path: .updateMemberPartial(type: type, id: id),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateMemberPartialRequest
        )
    }

    static func updateMessage(id: String, updateMessageRequest: UpdateMessageRequest) -> DefaultEndpoint<UpdateMessageResponse> {
        .init(
            path: .updateMessage(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateMessageRequest
        )
    }

    static func updateMessagePartial(id: String, updateMessagePartialRequest: UpdateMessagePartialRequest) -> DefaultEndpoint<UpdateMessagePartialResponse> {
        .init(
            path: .updateMessagePartial(id: id),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateMessagePartialRequest
        )
    }

    static func updatePoll(updatePollRequest: UpdatePollRequest) -> DefaultEndpoint<PollResponse> {
        .init(
            path: .updatePoll,
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: updatePollRequest
        )
    }

    static func updatePollOption(pollId: String, updatePollOptionRequest: UpdatePollOptionRequestOpenAPI) -> DefaultEndpoint<PollOptionResponseOpenAPI> {
        .init(
            path: .updatePollOption(pollId: pollId),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: updatePollOptionRequest
        )
    }

    static func updatePollPartial(pollId: String, updatePollPartialRequest: UpdatePollPartialRequest) -> DefaultEndpoint<PollResponse> {
        .init(
            path: .updatePollPartial(pollId: pollId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: updatePollPartialRequest
        )
    }

    static func updatePushNotificationPreferences(upsertPushPreferencesRequest: UpsertPushPreferencesRequest) -> DefaultEndpoint<UpsertPushPreferencesResponse> {
        .init(
            path: .updatePushNotificationPreferences,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: upsertPushPreferencesRequest
        )
    }

    static func updateReminder(messageId: String, updateReminderRequest: UpdateReminderRequest) -> DefaultEndpoint<UpdateReminderResponse> {
        .init(
            path: .updateReminder(messageId: messageId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateReminderRequest
        )
    }

    static func updateThreadPartial(messageId: String, updateThreadPartialRequest: UpdateThreadPartialRequest) -> DefaultEndpoint<UpdateThreadPartialResponse> {
        .init(
            path: .updateThreadPartial(messageId: messageId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateThreadPartialRequest
        )
    }

    static func updateUserGroup(id: String, updateUserGroupRequest: UpdateUserGroupRequest) -> DefaultEndpoint<UpdateUserGroupResponse> {
        .init(
            path: .updateUserGroup(id: id),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateUserGroupRequest
        )
    }

    static func updateUsers(updateUsersRequest: UpdateUsersRequest) -> DefaultEndpoint<UpdateUsersResponse> {
        .init(
            path: .updateUsers,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateUsersRequest
        )
    }

    static func updateUsersPartial(updateUsersPartialRequest: UpdateUsersPartialRequest) -> DefaultEndpoint<UpdateUsersResponse> {
        .init(
            path: .updateUsersPartial,
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateUsersPartialRequest
        )
    }

    static func uploadChannelFile(type: String, id: String, uploadChannelFileRequest: UploadChannelFileRequest) -> DefaultEndpoint<UploadChannelFileResponse> {
        .init(
            path: .uploadChannelFile(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: uploadChannelFileRequest
        )
    }

    static func uploadChannelImage(type: String, id: String, uploadChannelRequest: UploadChannelRequest) -> DefaultEndpoint<UploadChannelResponse> {
        .init(
            path: .uploadChannelImage(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: uploadChannelRequest
        )
    }

    static func uploadFile(fileUploadRequest: FileUploadRequest) -> DefaultEndpoint<FileUploadResponse> {
        .init(
            path: .uploadFile,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: fileUploadRequest
        )
    }

    static func uploadImage(imageUploadRequest: ImageUploadRequest) -> DefaultEndpoint<ImageUploadResponse> {
        .init(
            path: .uploadImage,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: imageUploadRequest
        )
    }

    static func upsertConfig(upsertConfigRequest: UpsertConfigRequest) -> DefaultEndpoint<UpsertConfigResponse> {
        .init(
            path: .upsertConfig,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: upsertConfigRequest
        )
    }
}
