//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class Endpoint<ResponseType: Decodable>: Codable, Sendable {
    let path: String
    let method: EndpointMethod
    let queryItems: [String: String?]?
    let requiresConnectionId: Bool
    let requiresToken: Bool
    let shouldBeQueuedOffline: Bool
    let body: (Encodable & Sendable)?

    init(
        path: String,
        method: EndpointMethod,
        queryItems: [String: String?]? = nil,
        requiresConnectionId: Bool = false,
        requiresToken: Bool = true,
        shouldBeQueuedOffline: Bool = false,
        body: (Encodable & Sendable)? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.requiresConnectionId = requiresConnectionId
        self.requiresToken = requiresToken
        self.shouldBeQueuedOffline = shouldBeQueuedOffline
        self.body = body
    }

    private enum CodingKeys: String, CodingKey {
        case path
        case method
        case queryItems
        case requiresConnectionId
        case requiresToken
        case shouldBeQueuedOffline
        case body
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(String.self, forKey: .path)
        method = try container.decode(EndpointMethod.self, forKey: .method)
        queryItems = try container.decodeIfPresent([String: String?].self, forKey: .queryItems)
        requiresConnectionId = try container.decode(Bool.self, forKey: .requiresConnectionId)
        requiresToken = try container.decode(Bool.self, forKey: .requiresToken)
        shouldBeQueuedOffline = try container.decode(Bool.self, forKey: .shouldBeQueuedOffline)
        body = try container.decodeIfPresent(Data.self, forKey: .body)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        try container.encode(method, forKey: .method)
        try container.encodeIfPresent(queryItems, forKey: .queryItems)
        try container.encode(requiresConnectionId, forKey: .requiresConnectionId)
        try container.encode(requiresToken, forKey: .requiresToken)
        try container.encode(shouldBeQueuedOffline, forKey: .shouldBeQueuedOffline)
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

extension Endpoint {
    static func ban(banRequest: BanRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<BanResponse> {
        .init(
            path: "/api/v2/moderation/ban",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: banRequest
        )
    }

    static func blockUsers(blockUsersRequest: BlockUsersRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<BlockUsersResponse> {
        .init(
            path: "/api/v2/users/block",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: blockUsersRequest
        )
    }

    static func castPollVote(messageId: String, pollId: String, castPollVoteRequest: CastPollVoteRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<PollVoteResponse> {
        .init(
            path: "/api/v2/chat/messages/\(messageId)/polls/\(pollId)/vote",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: castPollVoteRequest
        )
    }

    static func createDevice(createDeviceRequest: CreateDeviceRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<Response> {
        .init(
            path: "/api/v2/devices",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: createDeviceRequest
        )
    }

    static func createDraft(type: String, id: String, createDraftRequest: CreateDraftRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = true) -> Endpoint<CreateDraftResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/draft",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: createDraftRequest
        )
    }

    static func createGuest(createGuestRequest: CreateGuestRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<CreateGuestResponse> {
        .init(
            path: "/api/v2/guest",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            requiresToken: false,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: createGuestRequest
        )
    }

    static func createPoll(createPollRequest: CreatePollRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<PollResponse> {
        .init(
            path: "/api/v2/polls",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: createPollRequest
        )
    }

    static func createPollOption(pollId: String, createPollOptionRequest: CreatePollOptionRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<PollOptionResponse> {
        .init(
            path: "/api/v2/polls/\(pollId)/options",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: createPollOptionRequest
        )
    }

    static func createReminder(messageId: String, createReminderRequest: CreateReminderRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<ReminderResponseData> {
        .init(
            path: "/api/v2/chat/messages/\(messageId)/reminders",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: createReminderRequest
        )
    }

    static func deleteChannel(type: String, id: String, hardDelete: Bool?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<DeleteChannelResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)",
            method: .delete,
            queryItems: [
                "hard_delete": APIHelper.convertAnyToString(hardDelete)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func deleteChannelFile(type: String, id: String, url: String?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<Response> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/file",
            method: .delete,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func deleteChannelImage(type: String, id: String, url: String?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<Response> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/image",
            method: .delete,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func deleteDevice(id: String, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<Response> {
        .init(
            path: "/api/v2/devices",
            method: .delete,
            queryItems: [
                "id": APIHelper.convertAnyToString(id)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func deleteDraft(type: String, id: String, parentId: String?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = true) -> Endpoint<Response> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/draft",
            method: .delete,
            queryItems: [
                "parent_id": APIHelper.convertAnyToString(parentId)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func deleteFile(url: String?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<Response> {
        .init(
            path: "/api/v2/uploads/file",
            method: .delete,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func deleteImage(url: String?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<Response> {
        .init(
            path: "/api/v2/uploads/image",
            method: .delete,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func deleteMessage(id: String, hard: Bool?, deletedBy: String?, deleteForMe: Bool?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = true) -> Endpoint<DeleteMessageResponse> {
        .init(
            path: "/api/v2/chat/messages/\(id)",
            method: .delete,
            queryItems: [
                "hard": APIHelper.convertAnyToString(hard),
                "deleted_by": APIHelper.convertAnyToString(deletedBy),
                "delete_for_me": APIHelper.convertAnyToString(deleteForMe)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func deletePoll(pollId: String, userId: String?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<Response> {
        .init(
            path: "/api/v2/polls/\(pollId)",
            method: .delete,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func deletePollVote(messageId: String, pollId: String, voteId: String, userId: String?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<PollVoteResponse> {
        .init(
            path: "/api/v2/chat/messages/\(messageId)/polls/\(pollId)/vote/\(voteId)",
            method: .delete,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func deleteReaction(id: String, type: String, userId: String?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = true) -> Endpoint<DeleteReactionResponse> {
        .init(
            path: "/api/v2/chat/messages/\(id)/reaction/\(type)",
            method: .delete,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func deleteReminder(messageId: String, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<DeleteReminderResponse> {
        .init(
            path: "/api/v2/chat/messages/\(messageId)/reminders",
            method: .delete,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func flag(flagRequest: FlagRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<FlagResponse> {
        .init(
            path: "/api/v2/moderation/flag",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: flagRequest
        )
    }

    static func getApp(requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<GetApplicationResponse> {
        .init(
            path: "/api/v2/app",
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func getBlockedUsers(requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<GetBlockedUsersResponse> {
        .init(
            path: "/api/v2/users/block",
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func getDraft(type: String, id: String, parentId: String?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<GetDraftResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/draft",
            method: .get,
            queryItems: [
                "parent_id": APIHelper.convertAnyToString(parentId)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func getMessage(id: String, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<GetMessageResponse> {
        .init(
            path: "/api/v2/chat/messages/\(id)",
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func getOG(url: String, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<GetOGResponse> {
        .init(
            path: "/api/v2/og",
            method: .get,
            queryItems: [
                "url": APIHelper.convertAnyToString(url)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func getOrCreateChannel(type: String, id: String, channelGetOrCreateRequest: ChannelGetOrCreateRequest, requiresConnectionId: Bool = true, shouldBeQueuedOffline: Bool = false) -> Endpoint<ChannelStateResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/query",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: channelGetOrCreateRequest
        )
    }

    static func getOrCreateDistinctChannel(type: String, channelGetOrCreateRequest: ChannelGetOrCreateRequest, requiresConnectionId: Bool = true, shouldBeQueuedOffline: Bool = false) -> Endpoint<ChannelStateResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/query",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: channelGetOrCreateRequest
        )
    }

    static func getReactions(id: String, limit: Int?, offset: Int?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<GetReactionsResponse> {
        .init(
            path: "/api/v2/chat/messages/\(id)/reactions",
            method: .get,
            queryItems: [
                "limit": APIHelper.convertAnyToString(limit),
                "offset": APIHelper.convertAnyToString(offset)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func getReplies(parentId: String, limit: Int?, idGte: String?, idGt: String?, idLte: String?, idLt: String?, idAround: String?, sort: [SortParamRequest]?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<GetRepliesResponse> {
        .init(
            path: "/api/v2/chat/messages/\(parentId)/replies",
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
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func getThread(messageId: String, watch: Bool?, replyLimit: Int?, participantLimit: Int?, memberLimit: Int?, requiresConnectionId: Bool = true, shouldBeQueuedOffline: Bool = false) -> Endpoint<GetThreadResponse> {
        .init(
            path: "/api/v2/chat/threads/\(messageId)",
            method: .get,
            queryItems: [
                "watch": APIHelper.convertAnyToString(watch),
                "reply_limit": APIHelper.convertAnyToString(replyLimit),
                "participant_limit": APIHelper.convertAnyToString(participantLimit),
                "member_limit": APIHelper.convertAnyToString(memberLimit)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func getUserLiveLocations(requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<SharedLocationsResponse> {
        .init(
            path: "/api/v2/users/live_locations",
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func groupedQueryChannels(groupedQueryChannelsRequest: GroupedQueryChannelsRequest, requiresConnectionId: Bool = true, shouldBeQueuedOffline: Bool = false) -> Endpoint<GroupedQueryChannelsResponse> {
        .init(
            path: "/api/v2/chat/channels/grouped",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: groupedQueryChannelsRequest
        )
    }

    static func hideChannel(type: String, id: String, hideChannelRequest: HideChannelRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<HideChannelResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/hide",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: hideChannelRequest
        )
    }

    static func listDevices(requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<ListDevicesResponse> {
        .init(
            path: "/api/v2/devices",
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func markChannelsRead(markChannelsReadRequest: MarkChannelsReadRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<MarkReadResponse> {
        .init(
            path: "/api/v2/chat/channels/read",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: markChannelsReadRequest
        )
    }

    static func markDelivered(markDeliveredRequest: MarkDeliveredRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<MarkDeliveredResponse> {
        .init(
            path: "/api/v2/chat/channels/delivered",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: markDeliveredRequest
        )
    }

    static func markRead(type: String, id: String, markReadRequest: MarkReadRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<MarkReadResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/read",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: markReadRequest
        )
    }

    static func markUnread(type: String, id: String, markUnreadRequest: MarkUnreadRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<Response> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/unread",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: markUnreadRequest
        )
    }

    static func mute(muteRequest: MuteRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<MuteResponse> {
        .init(
            path: "/api/v2/moderation/mute",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: muteRequest
        )
    }

    static func muteChannel(muteChannelRequest: MuteChannelRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<MuteChannelResponse> {
        .init(
            path: "/api/v2/chat/moderation/mute/channel",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: muteChannelRequest
        )
    }

    static func queryChannels(queryChannelsRequest: QueryChannelsRequest, requiresConnectionId: Bool = true, shouldBeQueuedOffline: Bool = false) -> Endpoint<QueryChannelsResponse> {
        .init(
            path: "/api/v2/chat/channels",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: queryChannelsRequest
        )
    }

    static func queryDrafts(queryDraftsRequest: QueryDraftsRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<QueryDraftsResponse> {
        .init(
            path: "/api/v2/chat/drafts/query",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: queryDraftsRequest
        )
    }

    static func queryMembers(payload: QueryMembersPayload?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<MembersResponse> {
        .init(
            path: "/api/v2/chat/members",
            method: .get,
            queryItems: [
                "payload": payload.flatMap { try? CodableHelper.encode($0).get() }.flatMap { String(data: $0, encoding: .utf8) }
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func queryPollVotes(pollId: String, userId: String?, queryPollVotesRequest: QueryPollVotesRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<PollVotesResponse> {
        .init(
            path: "/api/v2/polls/\(pollId)/votes",
            method: .post,
            queryItems: [
                "user_id": APIHelper.convertAnyToString(userId)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: queryPollVotesRequest
        )
    }

    static func queryReactions(id: String, queryReactionsRequest: QueryReactionsRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<QueryReactionsResponse> {
        .init(
            path: "/api/v2/chat/messages/\(id)/reactions",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: queryReactionsRequest
        )
    }

    static func queryReminders(queryRemindersRequest: QueryRemindersRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<QueryRemindersResponse> {
        .init(
            path: "/api/v2/chat/reminders/query",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: queryRemindersRequest
        )
    }

    static func queryThreads(queryThreadsRequest: QueryThreadsRequest, requiresConnectionId: Bool = true, shouldBeQueuedOffline: Bool = false) -> Endpoint<QueryThreadsResponse> {
        .init(
            path: "/api/v2/chat/threads",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: queryThreadsRequest
        )
    }

    static func queryUsers(payload: QueryUsersPayload?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<QueryUsersResponse> {
        .init(
            path: "/api/v2/users",
            method: .get,
            queryItems: [
                "payload": payload.flatMap { try? CodableHelper.encode($0).get() }.flatMap { String(data: $0, encoding: .utf8) }
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func runMessageAction(id: String, messageActionRequest: MessageActionRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<MessageActionResponse> {
        .init(
            path: "/api/v2/chat/messages/\(id)/action",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: messageActionRequest
        )
    }

    static func search(payload: SearchPayload?, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<SearchResponse> {
        .init(
            path: "/api/v2/chat/search",
            method: .get,
            queryItems: [
                "payload": payload.flatMap { try? CodableHelper.encode($0).get() }.flatMap { String(data: $0, encoding: .utf8) }
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func sendEvent(type: String, id: String, sendEventRequest: SendEventRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<EventResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/event",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: sendEventRequest
        )
    }

    static func sendMessage(type: String, id: String, sendMessageRequest: SendMessageRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = true) -> Endpoint<SendMessageResponsePayload> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/message",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: sendMessageRequest
        )
    }

    static func sendReaction(id: String, sendReactionRequest: SendReactionRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = true) -> Endpoint<SendReactionResponse> {
        .init(
            path: "/api/v2/chat/messages/\(id)/reaction",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: sendReactionRequest
        )
    }

    static func showChannel(type: String, id: String, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<ShowChannelResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/show",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func stopWatchingChannel(type: String, id: String, requiresConnectionId: Bool = true, shouldBeQueuedOffline: Bool = false) -> Endpoint<Response> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/stop-watching",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func sync(syncRequest: SyncRequest, withInaccessibleCids: Bool?, watch: Bool?, requiresConnectionId: Bool = true, shouldBeQueuedOffline: Bool = false) -> Endpoint<SyncResponse> {
        .init(
            path: "/api/v2/chat/sync",
            method: .post,
            queryItems: [
                "with_inaccessible_cids": APIHelper.convertAnyToString(withInaccessibleCids),
                "watch": APIHelper.convertAnyToString(watch)
            ],
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: syncRequest
        )
    }

    static func translateMessage(id: String, translateMessageRequest: TranslateMessageRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<MessageActionResponse> {
        .init(
            path: "/api/v2/chat/messages/\(id)/translate",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: translateMessageRequest
        )
    }

    static func truncateChannel(type: String, id: String, truncateChannelRequest: TruncateChannelRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<TruncateChannelResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/truncate",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: truncateChannelRequest
        )
    }

    static func unblockUsers(unblockUsersRequest: UnblockUsersRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<UnblockUsersResponse> {
        .init(
            path: "/api/v2/users/unblock",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: unblockUsersRequest
        )
    }

    static func unmuteChannel(unmuteChannelRequest: UnmuteChannelRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<UnmuteResponse> {
        .init(
            path: "/api/v2/chat/moderation/unmute/channel",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: unmuteChannelRequest
        )
    }

    static func unreadCounts(requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<WrappedUnreadCountsResponse> {
        .init(
            path: "/api/v2/chat/unread",
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: nil
        )
    }

    static func updateChannel(type: String, id: String, updateChannelRequest: UpdateChannelRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<UpdateChannelResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: updateChannelRequest
        )
    }

    static func updateChannelPartial(type: String, id: String, updateChannelPartialRequest: UpdateChannelPartialRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<UpdateChannelPartialResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)",
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: updateChannelPartialRequest
        )
    }

    static func updateLiveLocation(updateLiveLocationRequest: UpdateLiveLocationRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<SharedLocationResponse> {
        .init(
            path: "/api/v2/users/live_locations",
            method: .put,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: updateLiveLocationRequest
        )
    }

    static func updateMemberPartial(type: String, id: String, updateMemberPartialRequest: UpdateMemberPartialRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<UpdateMemberPartialResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/member",
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: updateMemberPartialRequest
        )
    }

    static func updateMessage(id: String, updateMessageRequest: UpdateMessageRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = true) -> Endpoint<UpdateMessageResponse> {
        .init(
            path: "/api/v2/chat/messages/\(id)",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: updateMessageRequest
        )
    }

    static func updateMessagePartial(id: String, updateMessagePartialRequest: UpdateMessagePartialRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = true) -> Endpoint<UpdateMessagePartialResponse> {
        .init(
            path: "/api/v2/chat/messages/\(id)",
            method: .put,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: updateMessagePartialRequest
        )
    }

    static func updatePollPartial(pollId: String, updatePollPartialRequest: UpdatePollPartialRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<PollResponse> {
        .init(
            path: "/api/v2/polls/\(pollId)",
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: updatePollPartialRequest
        )
    }

    static func updatePushNotificationPreferences(upsertPushPreferencesRequest: UpsertPushPreferencesRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<UpsertPushPreferencesResponse> {
        .init(
            path: "/api/v2/push_preferences",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: upsertPushPreferencesRequest
        )
    }

    static func updateReminder(messageId: String, updateReminderRequest: UpdateReminderRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<UpdateReminderResponse> {
        .init(
            path: "/api/v2/chat/messages/\(messageId)/reminders",
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: updateReminderRequest
        )
    }

    static func updateThreadPartial(messageId: String, updateThreadPartialRequest: UpdateThreadPartialRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<UpdateThreadPartialResponse> {
        .init(
            path: "/api/v2/chat/threads/\(messageId)",
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: updateThreadPartialRequest
        )
    }

    static func updateUsersPartial(updateUsersPartialRequest: UpdateUsersPartialRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<UpdateUsersResponse> {
        .init(
            path: "/api/v2/users",
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: updateUsersPartialRequest
        )
    }

    static func uploadChannelFile(type: String, id: String, uploadChannelFileRequest: UploadChannelFileRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<UploadChannelFileResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/file",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: uploadChannelFileRequest
        )
    }

    static func uploadChannelImage(type: String, id: String, uploadChannelRequest: UploadChannelRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<UploadChannelResponse> {
        .init(
            path: "/api/v2/chat/channels/\(type)/\(id)/image",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: uploadChannelRequest
        )
    }

    static func uploadFile(fileUploadRequest: FileUploadRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<FileUploadResponse> {
        .init(
            path: "/api/v2/uploads/file",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: fileUploadRequest
        )
    }

    static func uploadImage(imageUploadRequest: ImageUploadRequest, requiresConnectionId: Bool = false, shouldBeQueuedOffline: Bool = false) -> Endpoint<ImageUploadResponse> {
        .init(
            path: "/api/v2/uploads/image",
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            shouldBeQueuedOffline: shouldBeQueuedOffline,
            body: imageUploadRequest
        )
    }
}
