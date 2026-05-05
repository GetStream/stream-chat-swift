//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class Endpoint<ResponseType: Decodable>: Codable, Sendable {
    let path: EndpointPath
    let method: EndpointMethod
    let queryItems: [String: String?]?
    let requiresConnectionId: Bool
    let requiresToken: Bool
    let body: (Encodable & Sendable)?

    init(
        path: EndpointPath,
        method: EndpointMethod,
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
        path = try container.decode(EndpointPath.self, forKey: .path)
        method = try container.decode(EndpointMethod.self, forKey: .method)
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

enum EndpointMethod: String, Codable, Equatable {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
    case put = "PUT"
}

enum EndpointPath: Codable, Equatable {
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
    case custom(String)

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
        case let .custom(path):
            return path
        }
    }
}

extension Endpoint {
    static func addUserGroupMembers(id: String, addUserGroupMembersRequest: AddUserGroupMembersRequest) -> Endpoint<AddUserGroupMembersResponse> {
        .init(
            path: .addUserGroupMembers(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: addUserGroupMembersRequest
        )
    }

    static func appeal(appealRequest: AppealRequest) -> Endpoint<AppealResponse> {
        .init(
            path: .appeal,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: appealRequest
        )
    }

    static func ban(banRequest: BanRequest) -> Endpoint<BanResponse> {
        .init(
            path: .ban,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: banRequest
        )
    }

    static func blockUsers(blockUsersRequest: BlockUsersRequest) -> Endpoint<BlockUsersResponse> {
        .init(
            path: .blockUsers,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: blockUsersRequest
        )
    }

    static func castPollVote(messageId: String, pollId: String, castPollVoteRequest: CastPollVoteRequest) -> Endpoint<PollVoteResponse> {
        .init(
            path: .castPollVote(messageId: messageId, pollId: pollId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: castPollVoteRequest
        )
    }

    static func createBlockList(createBlockListRequest: CreateBlockListRequest) -> Endpoint<CreateBlockListResponse> {
        .init(
            path: .createBlockList,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createBlockListRequest
        )
    }

    static func createDevice(createDeviceRequest: CreateDeviceRequest) -> Endpoint<Response> {
        .init(
            path: .createDevice,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createDeviceRequest
        )
    }

    static func createDraft(type: String, id: String, createDraftRequest: CreateDraftRequest) -> Endpoint<CreateDraftResponse> {
        .init(
            path: .createDraft(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createDraftRequest
        )
    }

    static func createGuest(createGuestRequest: CreateGuestRequest) -> Endpoint<CreateGuestResponse> {
        .init(
            path: .createGuest,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: false,
            body: createGuestRequest
        )
    }

    static func createPoll(createPollRequest: CreatePollRequest) -> Endpoint<PollResponse> {
        .init(
            path: .createPoll,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createPollRequest
        )
    }

    static func createPollOption(pollId: String, createPollOptionRequest: CreatePollOptionRequest) -> Endpoint<PollOptionResponseOpenAPI> {
        .init(
            path: .createPollOption(pollId: pollId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createPollOptionRequest
        )
    }

    static func createReminder(messageId: String, createReminderRequest: CreateReminderRequest) -> Endpoint<ReminderResponseData> {
        .init(
            path: .createReminder(messageId: messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createReminderRequest
        )
    }

    static func createUserGroup(createUserGroupRequest: CreateUserGroupRequest) -> Endpoint<CreateUserGroupResponse> {
        .init(
            path: .createUserGroup,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createUserGroupRequest
        )
    }

    static func deleteBlockList(name: String, team: String?) -> Endpoint<Response> {
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

    static func deleteChannel(type: String, id: String, hardDelete: Bool?) -> Endpoint<DeleteChannelResponse> {
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

    static func deleteChannelFile(type: String, id: String, url: String?) -> Endpoint<Response> {
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

    static func deleteChannelImage(type: String, id: String, url: String?) -> Endpoint<Response> {
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

    static func deleteChannels(deleteChannelsRequest: DeleteChannelsRequest) -> Endpoint<DeleteChannelsResponse> {
        .init(
            path: .deleteChannels,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: deleteChannelsRequest
        )
    }

    static func deleteConfig(key: String, team: String?) -> Endpoint<DeleteModerationConfigResponse> {
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

    static func deleteDevice(id: String) -> Endpoint<Response> {
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

    static func deleteDraft(type: String, id: String, parentId: String?) -> Endpoint<Response> {
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

    static func deleteFile(url: String?) -> Endpoint<Response> {
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

    static func deleteImage(url: String?) -> Endpoint<Response> {
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

    static func deleteMessage(id: String, hard: Bool?, deletedBy: String?, deleteForMe: Bool?) -> Endpoint<DeleteMessageResponse> {
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

    static func deletePoll(pollId: String, userId: String?) -> Endpoint<Response> {
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

    static func deletePollOption(pollId: String, optionId: String, userId: String?) -> Endpoint<Response> {
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

    static func deletePollVote(messageId: String, pollId: String, voteId: String, userId: String?) -> Endpoint<PollVoteResponse> {
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

    static func deleteReaction(id: String, type: String, userId: String?) -> Endpoint<DeleteReactionResponse> {
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

    static func deleteReminder(messageId: String) -> Endpoint<DeleteReminderResponse> {
        .init(
            path: .deleteReminder(messageId: messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteUserGroup(id: String, teamId: String?) -> Endpoint<Response> {
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

    static func flag(flagRequest: FlagRequest) -> Endpoint<FlagResponse> {
        .init(
            path: .flag,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: flagRequest
        )
    }

    static func getApp() -> Endpoint<GetApplicationResponse> {
        .init(
            path: .getApp,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getAppeal(id: String) -> Endpoint<GetAppealResponse> {
        .init(
            path: .getAppeal(id: id),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getBlockedUsers() -> Endpoint<GetBlockedUsersResponse> {
        .init(
            path: .getBlockedUsers,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getConfig(key: String, team: String?) -> Endpoint<GetConfigResponse> {
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

    static func getDraft(type: String, id: String, parentId: String?) -> Endpoint<GetDraftResponse> {
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

    static func getManyMessages(type: String, id: String, ids: [String]) -> Endpoint<GetManyMessagesResponse> {
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

    static func getMessage(id: String) -> Endpoint<GetMessageResponse> {
        .init(
            path: .getMessage(id: id),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getOG(url: String) -> Endpoint<GetOGResponse> {
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

    static func getOrCreateChannel(type: String, id: String, channelGetOrCreateRequest: ChannelGetOrCreateRequest) -> Endpoint<ChannelStateResponse> {
        .init(
            path: .getOrCreateChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: channelGetOrCreateRequest
        )
    }

    static func getOrCreateDistinctChannel(type: String, channelGetOrCreateRequest: ChannelGetOrCreateRequest) -> Endpoint<ChannelStateResponse> {
        .init(
            path: .getOrCreateDistinctChannel(type: type),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: channelGetOrCreateRequest
        )
    }

    static func getPoll(pollId: String, userId: String?) -> Endpoint<PollResponse> {
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

    static func getPollOption(pollId: String, optionId: String, userId: String?) -> Endpoint<PollOptionResponseOpenAPI> {
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

    static func getReactions(id: String, limit: Int?, offset: Int?) -> Endpoint<GetReactionsResponse> {
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

    static func getReplies(parentId: String, limit: Int?, idGte: String?, idGt: String?, idLte: String?, idLt: String?, idAround: String?, sort: [SortParamRequestOpenAPI]?) -> Endpoint<GetRepliesResponse> {
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

    static func getThread(messageId: String, watch: Bool?, replyLimit: Int?, participantLimit: Int?, memberLimit: Int?) -> Endpoint<GetThreadResponse> {
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

    static func getUserGroup(id: String, teamId: String?) -> Endpoint<GetUserGroupResponse> {
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

    static func getUserLiveLocations() -> Endpoint<SharedLocationsResponse> {
        .init(
            path: .getUserLiveLocations,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func groupedQueryChannels(groupedQueryChannelsRequest: GroupedQueryChannelsRequest) -> Endpoint<GroupedQueryChannelsResponse> {
        .init(
            path: .groupedQueryChannels,
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: groupedQueryChannelsRequest
        )
    }

    static func hideChannel(type: String, id: String, hideChannelRequest: HideChannelRequest) -> Endpoint<HideChannelResponse> {
        .init(
            path: .hideChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: hideChannelRequest
        )
    }

    static func listBlockLists(team: String?) -> Endpoint<ListBlockListResponse> {
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

    static func listDevices() -> Endpoint<ListDevicesResponse> {
        .init(
            path: .listDevices,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func listUserGroups(limit: Int?, idGt: String?, createdAtGt: String?, teamId: String?) -> Endpoint<ListUserGroupsResponse> {
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

    static func longPoll(json: WSAuthMessage?) -> Endpoint<EmptyResponse> {
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

    static func markChannelsRead(markChannelsReadRequest: MarkChannelsReadRequest) -> Endpoint<MarkReadResponse> {
        .init(
            path: .markChannelsRead,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: markChannelsReadRequest
        )
    }

    static func markDelivered(markDeliveredRequest: MarkDeliveredRequest) -> Endpoint<MarkDeliveredResponse> {
        .init(
            path: .markDelivered,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: markDeliveredRequest
        )
    }

    static func markRead(type: String, id: String, markReadRequest: MarkReadRequest) -> Endpoint<MarkReadResponse> {
        .init(
            path: .markRead(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: markReadRequest
        )
    }

    static func markUnread(type: String, id: String, markUnreadRequest: MarkUnreadRequest) -> Endpoint<Response> {
        .init(
            path: .markUnread(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: markUnreadRequest
        )
    }

    static func mute(muteRequest: MuteRequest) -> Endpoint<MuteResponse> {
        .init(
            path: .mute,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: muteRequest
        )
    }

    static func muteChannel(muteChannelRequest: MuteChannelRequest) -> Endpoint<MuteChannelResponse> {
        .init(
            path: .muteChannel,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: muteChannelRequest
        )
    }

    static func queryAppeals(queryAppealsRequest: QueryAppealsRequest) -> Endpoint<QueryAppealsResponse> {
        .init(
            path: .queryAppeals,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: queryAppealsRequest
        )
    }

    static func queryBannedUsers(payload: QueryBannedUsersPayload?) -> Endpoint<QueryBannedUsersResponse> {
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

    static func queryChannels(queryChannelsRequest: QueryChannelsRequest) -> Endpoint<QueryChannelsResponse> {
        .init(
            path: .queryChannels,
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: queryChannelsRequest
        )
    }

    static func queryDrafts(queryDraftsRequest: QueryDraftsRequest) -> Endpoint<QueryDraftsResponse> {
        .init(
            path: .queryDrafts,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: queryDraftsRequest
        )
    }

    static func queryFutureChannelBans(payload: QueryFutureChannelBansPayload?) -> Endpoint<QueryFutureChannelBansResponse> {
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

    static func queryMembers(payload: QueryMembersPayload?) -> Endpoint<MembersResponse> {
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

    static func queryMessageFlags(payload: QueryMessageFlagsPayload?) -> Endpoint<QueryMessageFlagsResponse> {
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

    static func queryModerationConfigs(queryModerationConfigsRequest: QueryModerationConfigsRequest) -> Endpoint<QueryModerationConfigsResponse> {
        .init(
            path: .queryModerationConfigs,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: queryModerationConfigsRequest
        )
    }

    static func queryPollVotes(pollId: String, userId: String?, queryPollVotesRequest: QueryPollVotesRequest) -> Endpoint<PollVotesResponse> {
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

    static func queryPolls(userId: String?, queryPollsRequest: QueryPollsRequest) -> Endpoint<QueryPollsResponse> {
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

    static func queryReactions(id: String, queryReactionsRequest: QueryReactionsRequest) -> Endpoint<QueryReactionsResponse> {
        .init(
            path: .queryReactions(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: queryReactionsRequest
        )
    }

    static func queryReminders(queryRemindersRequest: QueryRemindersRequest) -> Endpoint<QueryRemindersResponse> {
        .init(
            path: .queryReminders,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: queryRemindersRequest
        )
    }

    static func queryReviewQueue(queryReviewQueueRequest: QueryReviewQueueRequest) -> Endpoint<QueryReviewQueueResponse> {
        .init(
            path: .queryReviewQueue,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: queryReviewQueueRequest
        )
    }

    static func queryThreads(queryThreadsRequest: QueryThreadsRequest) -> Endpoint<QueryThreadsResponse> {
        .init(
            path: .queryThreads,
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: queryThreadsRequest
        )
    }

    static func queryUsers(payload: QueryUsersPayload?) -> Endpoint<QueryUsersResponse> {
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

    static func removeUserGroupMembers(id: String, removeUserGroupMembersRequest: RemoveUserGroupMembersRequest) -> Endpoint<RemoveUserGroupMembersResponse> {
        .init(
            path: .removeUserGroupMembers(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: removeUserGroupMembersRequest
        )
    }

    static func runMessageAction(id: String, messageActionRequest: MessageActionRequest) -> Endpoint<MessageActionResponse> {
        .init(
            path: .runMessageAction(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: messageActionRequest
        )
    }

    static func search(payload: SearchPayload?) -> Endpoint<SearchResponse> {
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

    static func searchUserGroups(query: String, limit: Int?, nameGt: String?, idGt: String?, teamId: String?) -> Endpoint<SearchUserGroupsResponse> {
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

    static func sendEvent(type: String, id: String, sendEventRequest: SendEventRequest) -> Endpoint<EventResponse> {
        .init(
            path: .sendEvent(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: sendEventRequest
        )
    }

    static func sendMessage(type: String, id: String, sendMessageRequest: SendMessageRequest) -> Endpoint<SendMessageResponseOpenAPI> {
        .init(
            path: .sendMessage(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: sendMessageRequest
        )
    }

    static func sendReaction(id: String, sendReactionRequest: SendReactionRequest) -> Endpoint<SendReactionResponse> {
        .init(
            path: .sendReaction(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: sendReactionRequest
        )
    }

    static func showChannel(type: String, id: String) -> Endpoint<ShowChannelResponse> {
        .init(
            path: .showChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func stopWatchingChannel(type: String, id: String) -> Endpoint<Response> {
        .init(
            path: .stopWatchingChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: nil
        )
    }

    static func submitAction(submitActionRequest: SubmitActionRequest) -> Endpoint<SubmitActionResponse> {
        .init(
            path: .submitAction,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: submitActionRequest
        )
    }

    static func sync(syncRequest: SyncRequest, withInaccessibleCids: Bool?, watch: Bool?) -> Endpoint<SyncResponse> {
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

    static func translateMessage(id: String, translateMessageRequest: TranslateMessageRequest) -> Endpoint<MessageActionResponse> {
        .init(
            path: .translateMessage(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: translateMessageRequest
        )
    }

    static func truncateChannel(type: String, id: String, truncateChannelRequest: TruncateChannelRequest) -> Endpoint<TruncateChannelResponse> {
        .init(
            path: .truncateChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: truncateChannelRequest
        )
    }

    static func unblockUsers(unblockUsersRequest: UnblockUsersRequest) -> Endpoint<UnblockUsersResponse> {
        .init(
            path: .unblockUsers,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: unblockUsersRequest
        )
    }

    static func unmuteChannel(unmuteChannelRequest: UnmuteChannelRequest) -> Endpoint<UnmuteResponse> {
        .init(
            path: .unmuteChannel,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: unmuteChannelRequest
        )
    }

    static func unreadCounts() -> Endpoint<WrappedUnreadCountsResponse> {
        .init(
            path: .unreadCounts,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func updateBlockList(name: String, updateBlockListRequest: UpdateBlockListRequest) -> Endpoint<UpdateBlockListResponse> {
        .init(
            path: .updateBlockList(name: name),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateBlockListRequest
        )
    }

    static func updateChannel(type: String, id: String, updateChannelRequest: UpdateChannelRequest) -> Endpoint<UpdateChannelResponse> {
        .init(
            path: .updateChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateChannelRequest
        )
    }

    static func updateChannelPartial(type: String, id: String, updateChannelPartialRequest: UpdateChannelPartialRequest) -> Endpoint<UpdateChannelPartialResponse> {
        .init(
            path: .updateChannelPartial(type: type, id: id),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateChannelPartialRequest
        )
    }

    static func updateLiveLocation(updateLiveLocationRequest: UpdateLiveLocationRequest) -> Endpoint<SharedLocationResponse> {
        .init(
            path: .updateLiveLocation,
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateLiveLocationRequest
        )
    }

    static func updateMemberPartial(type: String, id: String, updateMemberPartialRequest: UpdateMemberPartialRequest) -> Endpoint<UpdateMemberPartialResponse> {
        .init(
            path: .updateMemberPartial(type: type, id: id),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateMemberPartialRequest
        )
    }

    static func updateMessage(id: String, updateMessageRequest: UpdateMessageRequest) -> Endpoint<UpdateMessageResponse> {
        .init(
            path: .updateMessage(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateMessageRequest
        )
    }

    static func updateMessagePartial(id: String, updateMessagePartialRequest: UpdateMessagePartialRequest) -> Endpoint<UpdateMessagePartialResponse> {
        .init(
            path: .updateMessagePartial(id: id),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateMessagePartialRequest
        )
    }

    static func updatePoll(updatePollRequest: UpdatePollRequest) -> Endpoint<PollResponse> {
        .init(
            path: .updatePoll,
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: updatePollRequest
        )
    }

    static func updatePollOption(pollId: String, updatePollOptionRequest: UpdatePollOptionRequestOpenAPI) -> Endpoint<PollOptionResponseOpenAPI> {
        .init(
            path: .updatePollOption(pollId: pollId),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: updatePollOptionRequest
        )
    }

    static func updatePollPartial(pollId: String, updatePollPartialRequest: UpdatePollPartialRequest) -> Endpoint<PollResponse> {
        .init(
            path: .updatePollPartial(pollId: pollId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: updatePollPartialRequest
        )
    }

    static func updatePushNotificationPreferences(upsertPushPreferencesRequest: UpsertPushPreferencesRequest) -> Endpoint<UpsertPushPreferencesResponse> {
        .init(
            path: .updatePushNotificationPreferences,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: upsertPushPreferencesRequest
        )
    }

    static func updateReminder(messageId: String, updateReminderRequest: UpdateReminderRequest) -> Endpoint<UpdateReminderResponse> {
        .init(
            path: .updateReminder(messageId: messageId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateReminderRequest
        )
    }

    static func updateThreadPartial(messageId: String, updateThreadPartialRequest: UpdateThreadPartialRequest) -> Endpoint<UpdateThreadPartialResponse> {
        .init(
            path: .updateThreadPartial(messageId: messageId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateThreadPartialRequest
        )
    }

    static func updateUserGroup(id: String, updateUserGroupRequest: UpdateUserGroupRequest) -> Endpoint<UpdateUserGroupResponse> {
        .init(
            path: .updateUserGroup(id: id),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateUserGroupRequest
        )
    }

    static func updateUsers(updateUsersRequest: UpdateUsersRequest) -> Endpoint<UpdateUsersResponse> {
        .init(
            path: .updateUsers,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateUsersRequest
        )
    }

    static func updateUsersPartial(updateUsersPartialRequest: UpdateUsersPartialRequest) -> Endpoint<UpdateUsersResponse> {
        .init(
            path: .updateUsersPartial,
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: updateUsersPartialRequest
        )
    }

    static func uploadChannelFile(type: String, id: String, uploadChannelFileRequest: UploadChannelFileRequest) -> Endpoint<UploadChannelFileResponse> {
        .init(
            path: .uploadChannelFile(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: uploadChannelFileRequest
        )
    }

    static func uploadChannelImage(type: String, id: String, uploadChannelRequest: UploadChannelRequest) -> Endpoint<UploadChannelResponse> {
        .init(
            path: .uploadChannelImage(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: uploadChannelRequest
        )
    }

    static func uploadFile(fileUploadRequest: FileUploadRequest) -> Endpoint<FileUploadResponse> {
        .init(
            path: .uploadFile,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: fileUploadRequest
        )
    }

    static func uploadImage(imageUploadRequest: ImageUploadRequest) -> Endpoint<ImageUploadResponse> {
        .init(
            path: .uploadImage,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: imageUploadRequest
        )
    }

    static func upsertConfig(upsertConfigRequest: UpsertConfigRequest) -> Endpoint<UpsertConfigResponse> {
        .init(
            path: .upsertConfig,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: upsertConfigRequest
        )
    }
}
