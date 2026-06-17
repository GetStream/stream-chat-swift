//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum EndpointPath: Codable {
    case unflagMessage
    case unflagUser
    case pinnedMessages(type: String, id: String)
    case unbanMember
    case unmuteUser
    case webSocketConnect

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

    var value: String {
        switch self {
        case .unflagMessage: return "moderation/unflag"
        case .unflagUser: return "moderation/unflag"
        case let .pinnedMessages(type, id): return "/api/v2/chat/channels/\(type)/\(id)/pinned_messages"
        case .unbanMember: return "moderation/ban"
        case .unmuteUser: return "moderation/unmute"
        case .webSocketConnect: return "/api/v2/connect"

        case .ban:
            return "/api/v2/moderation/ban"
        case .blockUsers:
            return "/api/v2/users/block"
        case let .castPollVote(messageId: messageId, pollId: pollId):
            let messageIdPreEscape = "\(APIHelper.mapValueToPathItem(messageId))"
            let messageIdPostEscape = messageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
            let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(messageIdPostEscape)/polls/\(pollIdPostEscape)/vote"
        case .createDevice:
            return "/api/v2/devices"
        case let .createDraft(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/draft"
        case .createGuest:
            return "/api/v2/guest"
        case .createPoll:
            return "/api/v2/polls"
        case let .createPollOption(pollId: pollId):
            let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
            let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/polls/\(pollIdPostEscape)/options"
        case let .createReminder(messageId: messageId):
            let messageIdPreEscape = "\(APIHelper.mapValueToPathItem(messageId))"
            let messageIdPostEscape = messageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(messageIdPostEscape)/reminders"
        case let .deleteChannel(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)"
        case let .deleteChannelFile(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/file"
        case let .deleteChannelImage(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/image"
        case .deleteDevice:
            return "/api/v2/devices"
        case let .deleteDraft(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/draft"
        case .deleteFile:
            return "/api/v2/uploads/file"
        case .deleteImage:
            return "/api/v2/uploads/image"
        case let .deleteMessage(id: id):
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(idPostEscape)"
        case let .deletePoll(pollId: pollId):
            let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
            let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/polls/\(pollIdPostEscape)"
        case let .deletePollVote(messageId: messageId, pollId: pollId, voteId: voteId):
            let messageIdPreEscape = "\(APIHelper.mapValueToPathItem(messageId))"
            let messageIdPostEscape = messageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
            let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let voteIdPreEscape = "\(APIHelper.mapValueToPathItem(voteId))"
            let voteIdPostEscape = voteIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(messageIdPostEscape)/polls/\(pollIdPostEscape)/vote/\(voteIdPostEscape)"
        case let .deleteReaction(id: id, type: type):
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(idPostEscape)/reaction/\(typePostEscape)"
        case let .deleteReminder(messageId: messageId):
            let messageIdPreEscape = "\(APIHelper.mapValueToPathItem(messageId))"
            let messageIdPostEscape = messageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(messageIdPostEscape)/reminders"
        case .flag:
            return "/api/v2/moderation/flag"
        case .getApp:
            return "/api/v2/app"
        case .getBlockedUsers:
            return "/api/v2/users/block"
        case let .getDraft(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/draft"
        case let .getMessage(id: id):
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(idPostEscape)"
        case .getOG:
            return "/api/v2/og"
        case let .getOrCreateChannel(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/query"
        case let .getOrCreateDistinctChannel(type: type):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/query"
        case let .getReactions(id: id):
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(idPostEscape)/reactions"
        case let .getReplies(parentId: parentId):
            let parentIdPreEscape = "\(APIHelper.mapValueToPathItem(parentId))"
            let parentIdPostEscape = parentIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(parentIdPostEscape)/replies"
        case let .getThread(messageId: messageId):
            let messageIdPreEscape = "\(APIHelper.mapValueToPathItem(messageId))"
            let messageIdPostEscape = messageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/threads/\(messageIdPostEscape)"
        case .getUserLiveLocations:
            return "/api/v2/users/live_locations"
        case .groupedQueryChannels:
            return "/api/v2/chat/channels/grouped"
        case let .hideChannel(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/hide"
        case .listDevices:
            return "/api/v2/devices"
        case .markChannelsRead:
            return "/api/v2/chat/channels/read"
        case .markDelivered:
            return "/api/v2/chat/channels/delivered"
        case let .markRead(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/read"
        case let .markUnread(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/unread"
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
        case let .queryPollVotes(pollId: pollId):
            let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
            let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/polls/\(pollIdPostEscape)/votes"
        case let .queryReactions(id: id):
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(idPostEscape)/reactions"
        case .queryReminders:
            return "/api/v2/chat/reminders/query"
        case .queryThreads:
            return "/api/v2/chat/threads"
        case .queryUsers:
            return "/api/v2/users"
        case let .runMessageAction(id: id):
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(idPostEscape)/action"
        case .search:
            return "/api/v2/chat/search"
        case let .sendEvent(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/event"
        case let .sendMessage(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/message"
        case let .sendReaction(id: id):
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(idPostEscape)/reaction"
        case let .showChannel(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/show"
        case let .stopWatchingChannel(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/stop-watching"
        case .sync:
            return "/api/v2/chat/sync"
        case let .translateMessage(id: id):
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(idPostEscape)/translate"
        case let .truncateChannel(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/truncate"
        case .unblockUsers:
            return "/api/v2/users/unblock"
        case .unmuteChannel:
            return "/api/v2/chat/moderation/unmute/channel"
        case .unreadCounts:
            return "/api/v2/chat/unread"
        case let .updateChannel(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)"
        case let .updateChannelPartial(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)"
        case .updateLiveLocation:
            return "/api/v2/users/live_locations"
        case let .updateMemberPartial(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/member"
        case let .updateMessage(id: id):
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(idPostEscape)"
        case let .updateMessagePartial(id: id):
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(idPostEscape)"
        case let .updatePollPartial(pollId: pollId):
            let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
            let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/polls/\(pollIdPostEscape)"
        case .updatePushNotificationPreferences:
            return "/api/v2/push_preferences"
        case let .updateReminder(messageId: messageId):
            let messageIdPreEscape = "\(APIHelper.mapValueToPathItem(messageId))"
            let messageIdPostEscape = messageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/messages/\(messageIdPostEscape)/reminders"
        case let .updateThreadPartial(messageId: messageId):
            let messageIdPreEscape = "\(APIHelper.mapValueToPathItem(messageId))"
            let messageIdPostEscape = messageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/threads/\(messageIdPostEscape)"
        case .updateUsersPartial:
            return "/api/v2/users"
        case let .uploadChannelFile(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/file"
        case let .uploadChannelImage(type: type, id: id):
            let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
            let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
            let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return "/api/v2/chat/channels/\(typePostEscape)/\(idPostEscape)/image"
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
    static func ban(banRequest: BanRequest, requiresConnectionId: Bool = false) -> Endpoint<BanResponse> {
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

    static func castPollVote(messageId: String, pollId: String, castPollVoteRequest: CastPollVoteRequest, requiresConnectionId: Bool = false) -> Endpoint<PollVoteResponse> {
        return .init(
            path: .castPollVote(messageId: messageId, pollId: pollId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: castPollVoteRequest
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

    static func createDraft(type: String, id: String, createDraftRequest: CreateDraftRequest, requiresConnectionId: Bool = false) -> Endpoint<CreateDraftResponse> {
        return .init(
            path: .createDraft(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createDraftRequest
        )
    }

    static func createGuest(createGuestRequest: CreateGuestRequest, requiresConnectionId: Bool = false) -> Endpoint<CreateGuestResponse> {
        return .init(
            path: .createGuest,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            requiresToken: false,
            body: createGuestRequest
        )
    }

    static func createPoll(createPollRequest: CreatePollRequest, requiresConnectionId: Bool = false) -> Endpoint<PollResponse> {
        return .init(
            path: .createPoll,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createPollRequest
        )
    }

    static func createPollOption(pollId: String, createPollOptionRequest: CreatePollOptionRequest, requiresConnectionId: Bool = false) -> Endpoint<PollOptionResponse> {
        return .init(
            path: .createPollOption(pollId: pollId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createPollOptionRequest
        )
    }

    static func createReminder(messageId: String, createReminderRequest: CreateReminderRequest, requiresConnectionId: Bool = false) -> Endpoint<ReminderResponseData> {
        return .init(
            path: .createReminder(messageId: messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: createReminderRequest
        )
    }

    static func deleteChannel(type: String, id: String, hardDelete: Bool?, requiresConnectionId: Bool = false) -> Endpoint<DeleteChannelResponse> {
        return .init(
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
        return .init(
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
        return .init(
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

    static func deleteDraft(type: String, id: String, parentId: String?, requiresConnectionId: Bool = false) -> Endpoint<Response> {
        return .init(
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
        return .init(
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
        return .init(
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
        return .init(
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
        return .init(
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
        return .init(
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
        return .init(
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
        return .init(
            path: .deleteReminder(messageId: messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func flag(flagRequest: FlagRequest, requiresConnectionId: Bool = false) -> Endpoint<FlagResponse> {
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

    static func getDraft(type: String, id: String, parentId: String?, requiresConnectionId: Bool = false) -> Endpoint<GetDraftResponse> {
        return .init(
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
        return .init(
            path: .getMessage(id: id),
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func getOG(url: String, requiresConnectionId: Bool = false) -> Endpoint<GetOGResponse> {
        return .init(
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
        return .init(
            path: .getOrCreateChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: channelGetOrCreateRequest
        )
    }

    static func getOrCreateDistinctChannel(type: String, channelGetOrCreateRequest: ChannelGetOrCreateRequest, requiresConnectionId: Bool = true) -> Endpoint<ChannelStateResponse> {
        return .init(
            path: .getOrCreateDistinctChannel(type: type),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: channelGetOrCreateRequest
        )
    }

    static func getReactions(id: String, limit: Int?, offset: Int?, requiresConnectionId: Bool = false) -> Endpoint<GetReactionsResponse> {
        return .init(
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
        return .init(
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
        return .init(
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
        return .init(
            path: .getUserLiveLocations,
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func groupedQueryChannels(groupedQueryChannelsRequest: GroupedQueryChannelsRequest, requiresConnectionId: Bool = true) -> Endpoint<GroupedQueryChannelsResponse> {
        return .init(
            path: .groupedQueryChannels,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: groupedQueryChannelsRequest
        )
    }

    static func hideChannel(type: String, id: String, hideChannelRequest: HideChannelRequest, requiresConnectionId: Bool = false) -> Endpoint<HideChannelResponse> {
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

    static func markChannelsRead(markChannelsReadRequest: MarkChannelsReadRequest, requiresConnectionId: Bool = false) -> Endpoint<MarkReadResponse> {
        return .init(
            path: .markChannelsRead,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: markChannelsReadRequest
        )
    }

    static func markDelivered(markDeliveredRequest: MarkDeliveredRequest, requiresConnectionId: Bool = false) -> Endpoint<MarkDeliveredResponse> {
        return .init(
            path: .markDelivered,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: markDeliveredRequest
        )
    }

    static func markRead(type: String, id: String, markReadRequest: MarkReadRequest, requiresConnectionId: Bool = false) -> Endpoint<MarkReadResponse> {
        return .init(
            path: .markRead(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: markReadRequest
        )
    }

    static func markUnread(type: String, id: String, markUnreadRequest: MarkUnreadRequest, requiresConnectionId: Bool = false) -> Endpoint<Response> {
        return .init(
            path: .markUnread(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: markUnreadRequest
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

    static func muteChannel(muteChannelRequest: MuteChannelRequest, requiresConnectionId: Bool = false) -> Endpoint<MuteChannelResponse> {
        return .init(
            path: .muteChannel,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: muteChannelRequest
        )
    }

    static func queryChannels(queryChannelsRequest: QueryChannelsRequest, requiresConnectionId: Bool = true) -> Endpoint<QueryChannelsResponse> {
        return .init(
            path: .queryChannels,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: queryChannelsRequest
        )
    }

    static func queryDrafts(queryDraftsRequest: QueryDraftsRequest, requiresConnectionId: Bool = false) -> Endpoint<QueryDraftsResponse> {
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
            queryItems: [
                "payload": payload.flatMap { try? CodableHelper.encode($0).get() }.flatMap { String(data: $0, encoding: .utf8) }
            ],
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func queryPollVotes(pollId: String, userId: String?, queryPollVotesRequest: QueryPollVotesRequest, requiresConnectionId: Bool = false) -> Endpoint<PollVotesResponse> {
        return .init(
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
        return .init(
            path: .queryReactions(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: queryReactionsRequest
        )
    }

    static func queryReminders(queryRemindersRequest: QueryRemindersRequest, requiresConnectionId: Bool = false) -> Endpoint<QueryRemindersResponse> {
        return .init(
            path: .queryReminders,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: queryRemindersRequest
        )
    }

    static func queryThreads(queryThreadsRequest: QueryThreadsRequest, requiresConnectionId: Bool = true) -> Endpoint<QueryThreadsResponse> {
        return .init(
            path: .queryThreads,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: queryThreadsRequest
        )
    }

    static func queryUsers(payload: QueryUsersPayload?, requiresConnectionId: Bool = false) -> Endpoint<QueryUsersResponse> {
        return .init(
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
        return .init(
            path: .runMessageAction(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: messageActionRequest
        )
    }

    static func search(payload: SearchPayload?, requiresConnectionId: Bool = false) -> Endpoint<SearchResponse> {
        return .init(
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
        return .init(
            path: .sendEvent(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: sendEventRequest
        )
    }

    static func sendMessage(type: String, id: String, sendMessageRequest: SendMessageRequest, requiresConnectionId: Bool = false) -> Endpoint<SendMessageResponsePayload> {
        return .init(
            path: .sendMessage(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: sendMessageRequest
        )
    }

    static func sendReaction(id: String, sendReactionRequest: SendReactionRequest, requiresConnectionId: Bool = false) -> Endpoint<SendReactionResponse> {
        return .init(
            path: .sendReaction(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: sendReactionRequest
        )
    }

    static func showChannel(type: String, id: String, requiresConnectionId: Bool = false) -> Endpoint<ShowChannelResponse> {
        return .init(
            path: .showChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func stopWatchingChannel(type: String, id: String, requiresConnectionId: Bool = true) -> Endpoint<Response> {
        return .init(
            path: .stopWatchingChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func sync(syncRequest: SyncRequest, withInaccessibleCids: Bool?, watch: Bool?, requiresConnectionId: Bool = true) -> Endpoint<SyncResponse> {
        return .init(
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
        return .init(
            path: .translateMessage(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: translateMessageRequest
        )
    }

    static func truncateChannel(type: String, id: String, truncateChannelRequest: TruncateChannelRequest, requiresConnectionId: Bool = false) -> Endpoint<TruncateChannelResponse> {
        return .init(
            path: .truncateChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: truncateChannelRequest
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

    static func unmuteChannel(unmuteChannelRequest: UnmuteChannelRequest, requiresConnectionId: Bool = false) -> Endpoint<UnmuteResponse> {
        return .init(
            path: .unmuteChannel,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: unmuteChannelRequest
        )
    }

    static func unreadCounts(requiresConnectionId: Bool = false) -> Endpoint<WrappedUnreadCountsResponse> {
        return .init(
            path: .unreadCounts,
            method: .get,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: nil
        )
    }

    static func updateChannel(type: String, id: String, updateChannelRequest: UpdateChannelRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateChannelResponse> {
        return .init(
            path: .updateChannel(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateChannelRequest
        )
    }

    static func updateChannelPartial(type: String, id: String, updateChannelPartialRequest: UpdateChannelPartialRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateChannelPartialResponse> {
        return .init(
            path: .updateChannelPartial(type: type, id: id),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateChannelPartialRequest
        )
    }

    static func updateLiveLocation(updateLiveLocationRequest: UpdateLiveLocationRequest, requiresConnectionId: Bool = false) -> Endpoint<SharedLocationResponse> {
        return .init(
            path: .updateLiveLocation,
            method: .put,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateLiveLocationRequest
        )
    }

    static func updateMemberPartial(type: String, id: String, updateMemberPartialRequest: UpdateMemberPartialRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateMemberPartialResponse> {
        return .init(
            path: .updateMemberPartial(type: type, id: id),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateMemberPartialRequest
        )
    }

    static func updateMessage(id: String, updateMessageRequest: UpdateMessageRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateMessageResponse> {
        return .init(
            path: .updateMessage(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateMessageRequest
        )
    }

    static func updateMessagePartial(id: String, updateMessagePartialRequest: UpdateMessagePartialRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateMessagePartialResponse> {
        return .init(
            path: .updateMessagePartial(id: id),
            method: .put,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateMessagePartialRequest
        )
    }

    static func updatePollPartial(pollId: String, updatePollPartialRequest: UpdatePollPartialRequest, requiresConnectionId: Bool = false) -> Endpoint<PollResponse> {
        return .init(
            path: .updatePollPartial(pollId: pollId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updatePollPartialRequest
        )
    }

    static func updatePushNotificationPreferences(upsertPushPreferencesRequest: UpsertPushPreferencesRequest, requiresConnectionId: Bool = false) -> Endpoint<UpsertPushPreferencesResponse> {
        return .init(
            path: .updatePushNotificationPreferences,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: upsertPushPreferencesRequest
        )
    }

    static func updateReminder(messageId: String, updateReminderRequest: UpdateReminderRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateReminderResponse> {
        return .init(
            path: .updateReminder(messageId: messageId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateReminderRequest
        )
    }

    static func updateThreadPartial(messageId: String, updateThreadPartialRequest: UpdateThreadPartialRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateThreadPartialResponse> {
        return .init(
            path: .updateThreadPartial(messageId: messageId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateThreadPartialRequest
        )
    }

    static func updateUsersPartial(updateUsersPartialRequest: UpdateUsersPartialRequest, requiresConnectionId: Bool = false) -> Endpoint<UpdateUsersResponse> {
        return .init(
            path: .updateUsersPartial,
            method: .patch,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: updateUsersPartialRequest
        )
    }

    static func uploadChannelFile(type: String, id: String, uploadChannelFileRequest: UploadChannelFileRequest, requiresConnectionId: Bool = false) -> Endpoint<UploadChannelFileResponse> {
        return .init(
            path: .uploadChannelFile(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: uploadChannelFileRequest
        )
    }

    static func uploadChannelImage(type: String, id: String, uploadChannelRequest: UploadChannelRequest, requiresConnectionId: Bool = false) -> Endpoint<UploadChannelResponse> {
        return .init(
            path: .uploadChannelImage(type: type, id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: uploadChannelRequest
        )
    }

    static func uploadFile(fileUploadRequest: FileUploadRequest, requiresConnectionId: Bool = false) -> Endpoint<FileUploadResponse> {
        return .init(
            path: .uploadFile,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: fileUploadRequest
        )
    }

    static func uploadImage(imageUploadRequest: ImageUploadRequest, requiresConnectionId: Bool = false) -> Endpoint<ImageUploadResponse> {
        return .init(
            path: .uploadImage,
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId,
            body: imageUploadRequest
        )
    }
}
