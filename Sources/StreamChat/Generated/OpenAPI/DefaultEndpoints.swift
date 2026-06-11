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
    case ban
    case blockUsers
    case castPollVote(messageId: String, pollId: String)
    case createDevice
    case createDraft(type: String, id: String)
    case createGuest
    case createPoll
    case createPollOption(pollId: String)
    case createReminder(messageId: String)
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
    case flag
    case getApp
    case getBlockedUsers
    case getDraft(type: String, id: String)
    case getMessage(id: String)
    case getOG
    case getOrCreateChannel(type: String, id: String)
    case getOrCreateDistinctChannel(type: String)
    case getReactions(id: String)
    case getReplies(parentId: String)
    case getThread(messageId: String)
    case getUserLiveLocations
    case groupedQueryChannels
    case hideChannel(type: String, id: String)
    case listDevices
    case markChannelsRead
    case markDelivered
    case markRead(type: String, id: String)
    case markUnread(type: String, id: String)
    case mute
    case muteChannel
    case queryChannels
    case queryDrafts
    case queryMembers
    case queryPollVotes(pollId: String)
    case queryReactions(id: String)
    case queryReminders
    case queryThreads
    case queryUsers
    case runMessageAction(id: String)
    case search
    case sendEvent(type: String, id: String)
    case sendMessage(type: String, id: String)
    case sendReaction(id: String)
    case showChannel(type: String, id: String)
    case stopWatchingChannel(type: String, id: String)
    case sync
    case translateMessage(id: String)
    case truncateChannel(type: String, id: String)
    case unblockUsers
    case unmuteChannel
    case unreadCounts
    case updateChannel(type: String, id: String)
    case updateChannelPartial(type: String, id: String)
    case updateLiveLocation
    case updateMemberPartial(type: String, id: String)
    case updateMessage(id: String)
    case updateMessagePartial(id: String)
    case updatePollPartial(pollId: String)
    case updatePushNotificationPreferences
    case updateReminder(messageId: String)
    case updateThreadPartial(messageId: String)
    case updateUsersPartial
    case uploadChannelFile(type: String, id: String)
    case uploadChannelImage(type: String, id: String)
    case uploadFile
    case uploadImage
    case custom(String)

    var value: String {
        switch self {
        case .ban:
            return "/api/v2/moderation/ban"
        case .blockUsers:
            return "/api/v2/users/block"
        case let .castPollVote(messageId, pollId):
            return "/api/v2/chat/messages/\(messageId)/polls/\(pollId)/vote"
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
        case let .deleteChannel(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)"
        case let .deleteChannelFile(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/file"
        case let .deleteChannelImage(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/image"
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
        case let .deletePollVote(messageId, pollId, voteId):
            return "/api/v2/chat/messages/\(messageId)/polls/\(pollId)/vote/\(voteId)"
        case let .deleteReaction(id, type):
            return "/api/v2/chat/messages/\(id)/reaction/\(type)"
        case let .deleteReminder(messageId):
            return "/api/v2/chat/messages/\(messageId)/reminders"
        case .flag:
            return "/api/v2/moderation/flag"
        case .getApp:
            return "/api/v2/app"
        case .getBlockedUsers:
            return "/api/v2/users/block"
        case let .getDraft(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/draft"
        case let .getMessage(id):
            return "/api/v2/chat/messages/\(id)"
        case .getOG:
            return "/api/v2/og"
        case let .getOrCreateChannel(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/query"
        case let .getOrCreateDistinctChannel(type):
            return "/api/v2/chat/channels/\(type)/query"
        case let .getReactions(id):
            return "/api/v2/chat/messages/\(id)/reactions"
        case let .getReplies(parentId):
            return "/api/v2/chat/messages/\(parentId)/replies"
        case let .getThread(messageId):
            return "/api/v2/chat/threads/\(messageId)"
        case .getUserLiveLocations:
            return "/api/v2/users/live_locations"
        case .groupedQueryChannels:
            return "/api/v2/chat/channels/grouped"
        case let .hideChannel(type, id):
            return "/api/v2/chat/channels/\(type)/\(id)/hide"
        case .listDevices:
            return "/api/v2/devices"
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
        case .queryChannels:
            return "/api/v2/chat/channels"
        case .queryDrafts:
            return "/api/v2/chat/drafts/query"
        case .queryMembers:
            return "/api/v2/chat/members"
        case let .queryPollVotes(pollId):
            return "/api/v2/polls/\(pollId)/votes"
        case let .queryReactions(id):
            return "/api/v2/chat/messages/\(id)/reactions"
        case .queryReminders:
            return "/api/v2/chat/reminders/query"
        case .queryThreads:
            return "/api/v2/chat/threads"
        case .queryUsers:
            return "/api/v2/users"
        case let .runMessageAction(id):
            return "/api/v2/chat/messages/\(id)/action"
        case .search:
            return "/api/v2/chat/search"
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
        case let .updatePollPartial(pollId):
            return "/api/v2/polls/\(pollId)"
        case .updatePushNotificationPreferences:
            return "/api/v2/push_preferences"
        case let .updateReminder(messageId):
            return "/api/v2/chat/messages/\(messageId)/reminders"
        case let .updateThreadPartial(messageId):
            return "/api/v2/chat/threads/\(messageId)"
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
        case let .custom(path):
            return path
        }
    }
}

extension Endpoint {
    static func ban(banRequest: BanRequest, requiresConnectionId: Bool = false) -> Endpoint<BanResponse> {
        .init(
            path: .ban,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: banRequest
        )
    }

    static func blockUsers(blockUsersRequest: BlockUsersRequest, requiresConnectionId: Bool = false) -> Endpoint<BlockUsersResponse> {
        .init(
            path: .blockUsers,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: blockUsersRequest
        )
    }

    static func castPollVote(messageId: String, pollId: String, castPollVoteRequest: CastPollVoteRequest, requiresConnectionId: Bool = false) -> Endpoint<PollVoteResponse> {
        .init(
            path: .castPollVote(messageId: messageId, pollId: pollId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: castPollVoteRequest
        )
    }

    static func createDevice(createDeviceRequest: CreateDeviceRequest, requiresConnectionId: Bool = false) -> Endpoint<Response> {
        .init(
            path: .createDevice,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createDeviceRequest
        )
    }

    static func createDraft(type: String, id: String, createDraftRequest: CreateDraftRequest, requiresConnectionId: Bool = false) -> Endpoint<CreateDraftResponse> {
        .init(
            path: .createDraft(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createDraftRequest
        )
    }

    static func createGuest(createGuestRequest: CreateGuestRequest, requiresConnectionId: Bool = false) -> Endpoint<CreateGuestResponse> {
        .init(
            path: .createGuest,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            requiresToken: false,
            body: createGuestRequest
        )
    }

    static func createPoll(createPollRequest: CreatePollRequest, requiresConnectionId: Bool = false) -> Endpoint<PollResponse> {
        .init(
            path: .createPoll,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createPollRequest
        )
    }

    static func createPollOption(pollId: String, createPollOptionRequest: CreatePollOptionRequest, requiresConnectionId: Bool = false) -> Endpoint<PollOptionResponse> {
        .init(
            path: .createPollOption(pollId: pollId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createPollOptionRequest
        )
    }

    static func createReminder(messageId: String, createReminderRequest: CreateReminderRequest, requiresConnectionId: Bool = false) -> Endpoint<ReminderResponseData> {
        .init(
            path: .createReminder(messageId: messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createReminderRequest
        )
    }

    static func deleteChannel(type: String, id: String, hardDelete: Bool?, requiresConnectionId: Bool = false) -> Endpoint<DeleteChannelResponse> {
        .init(
            path: .deleteChannel(type: type, id: id),
            method: .delete,
            queryItems: [
                "hard_delete": APIHelper.convertAnyToString(hardDelete)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteChannelFile(type: String, id: String, url: String?, requiresConnectionId: Bool = false) -> Endpoint<Response> {
        .init(
            path: .deleteChannelFile(type: type, id: id),
            method: .delete,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteChannelImage(type: String, id: String, url: String?, requiresConnectionId: Bool = false) -> Endpoint<Response> {
        .init(
            path: .deleteChannelImage(type: type, id: id),
            method: .delete,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteDevice(id: String, requiresConnectionId: Bool = false) -> Endpoint<Response> {
        .init(
            path: .deleteDevice,
            method: .delete,
            queryItems: [
                "id": APIHelper.convertAnyToString(id)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteDraft(type: String, id: String, parentId: String?, requiresConnectionId: Bool = false) -> Endpoint<Response> {
        .init(
            path: .deleteDraft(type: type, id: id),
            method: .delete,
            queryItems: [
                "parent_id": APIHelper.convertAnyToString(parentId)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteFile(url: String?, requiresConnectionId: Bool = false) -> Endpoint<Response> {
        .init(
            path: .deleteFile,
            method: .delete,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteImage(url: String?, requiresConnectionId: Bool = false) -> Endpoint<Response> {
        .init(
            path: .deleteImage,
            method: .delete,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteMessage(id: String, hard: Bool?, deletedBy: String?, deleteForMe: Bool?, requiresConnectionId: Bool = false) -> Endpoint<DeleteMessageResponse> {
        .init(
            path: .deleteMessage(id: id),
            method: .delete,
            queryItems: [
                "hard": APIHelper.convertAnyToString(hard),
                "deleted_by": APIHelper.convertAnyToString(deletedBy),
                "delete_for_me": APIHelper.convertAnyToString(deleteForMe)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deletePoll(pollId: String, userId: String?, requiresConnectionId: Bool = false) -> Endpoint<Response> {
        .init(
            path: .deletePoll(pollId: pollId),
            method: .delete,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deletePollVote(messageId: String, pollId: String, voteId: String, userId: String?, requiresConnectionId: Bool = false) -> Endpoint<PollVoteResponse> {
        .init(
            path: .deletePollVote(messageId: messageId, pollId: pollId, voteId: voteId),
            method: .delete,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteReaction(id: String, type: String, userId: String?, requiresConnectionId: Bool = false) -> Endpoint<DeleteReactionResponse> {
        .init(
            path: .deleteReaction(id: id, type: type),
            method: .delete,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func deleteReminder(messageId: String, requiresConnectionId: Bool = false) -> Endpoint<DeleteReminderResponse> {
        .init(
            path: .deleteReminder(messageId: messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func flag(flagRequest: FlagRequest, requiresConnectionId: Bool = false) -> Endpoint<FlagResponse> {
        .init(
            path: .flag,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: flagRequest
        )
    }

    static func getApp(requiresConnectionId: Bool = false) -> Endpoint<GetApplicationResponse> {
        .init(
            path: .getApp,
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getBlockedUsers(requiresConnectionId: Bool = false) -> Endpoint<GetBlockedUsersResponse> {
        .init(
            path: .getBlockedUsers,
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getDraft(type: String, id: String, parentId: String?, requiresConnectionId: Bool = false) -> Endpoint<GetDraftResponse> {
        .init(
            path: .getDraft(type: type, id: id),
            method: .get,
            queryItems: [
                "parent_id": APIHelper.convertAnyToString(parentId)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getMessage(id: String, requiresConnectionId: Bool = false) -> Endpoint<GetMessageResponse> {
        .init(
            path: .getMessage(id: id),
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getOG(url: String, requiresConnectionId: Bool = false) -> Endpoint<GetOGResponse> {
        .init(
            path: .getOG,
            method: .get,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getOrCreateChannel(type: String, id: String, channelGetOrCreateRequest: ChannelGetOrCreateRequest, requiresConnectionId: Bool = true) -> Endpoint<ChannelStateResponse> {
        .init(
            path: .getOrCreateChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: channelGetOrCreateRequest
        )
    }

    static func getOrCreateDistinctChannel(type: String, channelGetOrCreateRequest: ChannelGetOrCreateRequest, requiresConnectionId: Bool = true) -> Endpoint<ChannelStateResponse> {
        .init(
            path: .getOrCreateDistinctChannel(type: type),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: channelGetOrCreateRequest
        )
    }

    static func getReactions(id: String, limit: Int?, offset: Int?, requiresConnectionId: Bool = false) -> Endpoint<GetReactionsResponse> {
        .init(
            path: .getReactions(id: id),
            method: .get,
            queryItems: [
                "limit": APIHelper.convertAnyToString(limit),
                "offset": APIHelper.convertAnyToString(offset)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getReplies(parentId: String, limit: Int?, idGte: String?, idGt: String?, idLte: String?, idLt: String?, idAround: String?, sort: [SortParamRequest]?, requiresConnectionId: Bool = false) -> Endpoint<GetRepliesResponse> {
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
                "sort": sort.flatMap { try? CodableHelper.encode($0).get() }.flatMap { String(data: $0, encoding: .utf8) }
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getThread(messageId: String, watch: Bool?, replyLimit: Int?, participantLimit: Int?, memberLimit: Int?, requiresConnectionId: Bool = true) -> Endpoint<GetThreadResponse> {
        .init(
            path: .getThread(messageId: messageId),
            method: .get,
            queryItems: [
                "watch": APIHelper.convertAnyToString(watch),
                "reply_limit": APIHelper.convertAnyToString(replyLimit),
                "participant_limit": APIHelper.convertAnyToString(participantLimit),
                "member_limit": APIHelper.convertAnyToString(memberLimit)
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getUserLiveLocations(requiresConnectionId: Bool = false) -> Endpoint<SharedLocationsResponse> {
        .init(
            path: .getUserLiveLocations,
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func groupedQueryChannels(groupedQueryChannelsRequest: GroupedQueryChannelsRequest, requiresConnectionId: Bool = true) -> Endpoint<GroupedQueryChannelsResponse> {
        .init(
            path: .groupedQueryChannels,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: groupedQueryChannelsRequest
        )
    }

    static func hideChannel(type: String, id: String, hideChannelRequest: HideChannelRequest, requiresConnectionId: Bool = false) -> Endpoint<HideChannelResponse> {
        .init(
            path: .hideChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: hideChannelRequest
        )
    }

    static func listDevices(requiresConnectionId: Bool = false) -> Endpoint<ListDevicesResponse> {
        .init(
            path: .listDevices,
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func markChannelsRead(markChannelsReadRequest: MarkChannelsReadRequest, requiresConnectionId: Bool = false) -> Endpoint<MarkReadResponse> {
        .init(
            path: .markChannelsRead,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: markChannelsReadRequest
        )
    }

    static func markDelivered(markDeliveredRequest: MarkDeliveredRequest, requiresConnectionId: Bool = false) -> Endpoint<MarkDeliveredResponse> {
        .init(
            path: .markDelivered,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: markDeliveredRequest
        )
    }

    static func markRead(type: String, id: String, markReadRequest: MarkReadRequest, requiresConnectionId: Bool = false) -> Endpoint<MarkReadResponse> {
        .init(
            path: .markRead(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: markReadRequest
        )
    }

    static func markUnread(type: String, id: String, markUnreadRequest: MarkUnreadRequest, requiresConnectionId: Bool = false) -> Endpoint<Response> {
        .init(
            path: .markUnread(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: markUnreadRequest
        )
    }

    static func mute(muteRequest: MuteRequest, requiresConnectionId: Bool = false) -> Endpoint<MuteResponse> {
        .init(
            path: .mute,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: muteRequest
        )
    }

    static func muteChannel(muteChannelRequest: MuteChannelRequest, requiresConnectionId: Bool = false) -> Endpoint<MuteChannelResponse> {
        .init(
            path: .muteChannel,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: muteChannelRequest
        )
    }

    static func queryChannels(queryChannelsRequest: QueryChannelsRequest, requiresConnectionId: Bool = true) -> Endpoint<QueryChannelsResponse> {
        .init(
            path: .queryChannels,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: queryChannelsRequest
        )
    }

    static func queryDrafts(queryDraftsRequest: QueryDraftsRequest, requiresConnectionId: Bool = false) -> Endpoint<QueryDraftsResponse> {
        .init(
            path: .queryDrafts,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: queryDraftsRequest
        )
    }

    static func queryMembers(payload: QueryMembersPayload?, requiresConnectionId: Bool = false) -> Endpoint<MembersResponse> {
        .init(
            path: .queryMembers,
            method: .get,
            queryItems: [
                "payload": payload.flatMap { try? CodableHelper.encode($0).get() }.flatMap { String(data: $0, encoding: .utf8) }
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func queryPollVotes(pollId: String, userId: String?, queryPollVotesRequest: QueryPollVotesRequest, requiresConnectionId: Bool = false) -> Endpoint<PollVotesResponse> {
        .init(
            path: .queryPollVotes(pollId: pollId),
            method: .post,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: requiresConnectionId,
            body: queryPollVotesRequest
        )
    }

    static func queryReactions(id: String, queryReactionsRequest: QueryReactionsRequest, requiresConnectionId: Bool = false) -> Endpoint<QueryReactionsResponse> {
        .init(
            path: .queryReactions(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: queryReactionsRequest
        )
    }

    static func queryReminders(queryRemindersRequest: QueryRemindersRequest, requiresConnectionId: Bool = false) -> Endpoint<QueryRemindersResponse> {
        .init(
            path: .queryReminders,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: queryRemindersRequest
        )
    }

    static func queryThreads(queryThreadsRequest: QueryThreadsRequest, requiresConnectionId: Bool = true) -> Endpoint<QueryThreadsResponse> {
        .init(
            path: .queryThreads,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: queryThreadsRequest
        )
    }

    static func queryUsers(payload: QueryUsersPayload?, requiresConnectionId: Bool = false) -> Endpoint<QueryUsersResponse> {
        .init(
            path: .queryUsers,
            method: .get,
            queryItems: [
                "payload": payload.flatMap { try? CodableHelper.encode($0).get() }.flatMap { String(data: $0, encoding: .utf8) }
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func runMessageAction(id: String, messageActionRequest: MessageActionRequest, requiresConnectionId: Bool = false) -> Endpoint<MessageActionResponse> {
        .init(
            path: .runMessageAction(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: messageActionRequest
        )
    }

    static func search(payload: SearchPayload?, requiresConnectionId: Bool = false) -> Endpoint<SearchResponse> {
        .init(
            path: .search,
            method: .get,
            queryItems: [
                "payload": payload.flatMap { try? CodableHelper.encode($0).get() }.flatMap { String(data: $0, encoding: .utf8) }
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func sendEvent(type: String, id: String, sendEventRequest: SendEventRequest, requiresConnectionId: Bool = false) -> Endpoint<EventResponse> {
        .init(
            path: .sendEvent(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: sendEventRequest
        )
    }

    static func sendMessage(type: String, id: String, sendMessageRequest: SendMessageRequest, requiresConnectionId: Bool = false) -> Endpoint<SendMessageResponsePayload> {
        .init(
            path: .sendMessage(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: sendMessageRequest
        )
    }

    static func sendReaction(id: String, sendReactionRequest: SendReactionRequest, requiresConnectionId: Bool = false) -> Endpoint<SendReactionResponse> {
        .init(
            path: .sendReaction(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: sendReactionRequest
        )
    }

    static func showChannel(type: String, id: String, requiresConnectionId: Bool = false) -> Endpoint<ShowChannelResponse> {
        .init(
            path: .showChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func stopWatchingChannel(type: String, id: String, requiresConnectionId: Bool = true) -> Endpoint<Response> {
        .init(
            path: .stopWatchingChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func sync(syncRequest: SyncRequest, withInaccessibleCids: Bool?, watch: Bool?, requiresConnectionId: Bool = true) -> Endpoint<SyncResponse> {
        .init(
            path: .sync,
            method: .post,
            queryItems: [
                "with_inaccessible_cids": APIHelper.convertAnyToString(withInaccessibleCids),
                "watch": APIHelper.convertAnyToString(watch)
            ],
            requiresConnectionId: requiresConnectionId,
            body: syncRequest
        )
    }

    static func translateMessage(id: String, translateMessageRequest: TranslateMessageRequest, requiresConnectionId: Bool = false) -> Endpoint<MessageActionResponse> {
        .init(
            path: .translateMessage(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: translateMessageRequest
        )
    }

    static func truncateChannel(type: String, id: String, truncateChannelRequest: TruncateChannelRequest, requiresConnectionId: Bool = false) -> Endpoint<TruncateChannelResponse> {
        .init(
            path: .truncateChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: truncateChannelRequest
        )
    }

    static func unblockUsers(unblockUsersRequest: UnblockUsersRequest, requiresConnectionId: Bool = false) -> Endpoint<UnblockUsersResponse> {
        .init(
            path: .unblockUsers,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: unblockUsersRequest
        )
    }

    static func unmuteChannel(unmuteChannelRequest: UnmuteChannelRequest, requiresConnectionId: Bool = false) -> Endpoint<UnmuteResponse> {
        .init(
            path: .unmuteChannel,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: unmuteChannelRequest
        )
    }

    static func unreadCounts(requiresConnectionId: Bool = false) -> Endpoint<WrappedUnreadCountsResponse> {
        .init(
            path: .unreadCounts,
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func updateChannel(type: String, id: String, updateChannelRequest: UpdateChannelRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateChannelResponse> {
        .init(
            path: .updateChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateChannelRequest
        )
    }

    static func updateChannelPartial(type: String, id: String, updateChannelPartialRequest: UpdateChannelPartialRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateChannelPartialResponse> {
        .init(
            path: .updateChannelPartial(type: type, id: id),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateChannelPartialRequest
        )
    }

    static func updateLiveLocation(updateLiveLocationRequest: UpdateLiveLocationRequest, requiresConnectionId: Bool = false) -> Endpoint<SharedLocationResponse> {
        .init(
            path: .updateLiveLocation,
            method: .put,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateLiveLocationRequest
        )
    }

    static func updateMemberPartial(type: String, id: String, updateMemberPartialRequest: UpdateMemberPartialRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateMemberPartialResponse> {
        .init(
            path: .updateMemberPartial(type: type, id: id),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateMemberPartialRequest
        )
    }

    static func updateMessage(id: String, updateMessageRequest: UpdateMessageRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateMessageResponse> {
        .init(
            path: .updateMessage(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateMessageRequest
        )
    }

    static func updateMessagePartial(id: String, updateMessagePartialRequest: UpdateMessagePartialRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateMessagePartialResponse> {
        .init(
            path: .updateMessagePartial(id: id),
            method: .put,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateMessagePartialRequest
        )
    }

    static func updatePollPartial(pollId: String, updatePollPartialRequest: UpdatePollPartialRequest, requiresConnectionId: Bool = false) -> Endpoint<PollResponse> {
        .init(
            path: .updatePollPartial(pollId: pollId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updatePollPartialRequest
        )
    }

    static func updatePushNotificationPreferences(upsertPushPreferencesRequest: UpsertPushPreferencesRequest, requiresConnectionId: Bool = false) -> Endpoint<UpsertPushPreferencesResponse> {
        .init(
            path: .updatePushNotificationPreferences,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: upsertPushPreferencesRequest
        )
    }

    static func updateReminder(messageId: String, updateReminderRequest: UpdateReminderRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateReminderResponse> {
        .init(
            path: .updateReminder(messageId: messageId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateReminderRequest
        )
    }

    static func updateThreadPartial(messageId: String, updateThreadPartialRequest: UpdateThreadPartialRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateThreadPartialResponse> {
        .init(
            path: .updateThreadPartial(messageId: messageId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateThreadPartialRequest
        )
    }

    static func updateUsersPartial(updateUsersPartialRequest: UpdateUsersPartialRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateUsersResponse> {
        .init(
            path: .updateUsersPartial,
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateUsersPartialRequest
        )
    }

    static func uploadChannelFile(type: String, id: String, uploadChannelFileRequest: UploadChannelFileRequest, requiresConnectionId: Bool = false) -> Endpoint<UploadChannelFileResponse> {
        .init(
            path: .uploadChannelFile(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: uploadChannelFileRequest
        )
    }

    static func uploadChannelImage(type: String, id: String, uploadChannelRequest: UploadChannelRequest, requiresConnectionId: Bool = false) -> Endpoint<UploadChannelResponse> {
        .init(
            path: .uploadChannelImage(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: uploadChannelRequest
        )
    }

    static func uploadFile(fileUploadRequest: FileUploadRequest, requiresConnectionId: Bool = false) -> Endpoint<FileUploadResponse> {
        .init(
            path: .uploadFile,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: fileUploadRequest
        )
    }

    static func uploadImage(imageUploadRequest: ImageUploadRequest, requiresConnectionId: Bool = false) -> Endpoint<ImageUploadResponse> {
        .init(
            path: .uploadImage,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: imageUploadRequest
        )
    }
}
