//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

enum EndpointPath: Codable {
    case connect
    case sync
    case users
    case guest
    case members
    case search
    case devices
    case og
    case unread

    case threads
    case thread(messageId: MessageId)
    case markThreadRead(cid: ChannelId)
    case markThreadUnread(cid: ChannelId)

    case channels
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
    case channelEvent(String)
    case stopWatchingChannel(String)
    case pinnedMessages(String)
    case uploadAttachment(channelId: String, type: String)

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

    case banMember
    case flagUser(Bool)
    case flagMessage(Bool)
    case muteUser(Bool)
    case blockUser
    case unblockUser

    case callToken(String)
    case createCall(String)
    
    case deleteFile(String)
    case deleteImage(String)

    case appSettings
    
    case polls
    case pollsQuery
    case poll(pollId: String)
    case pollOption(pollId: String, optionId: String)
    case pollOptions(pollId: String)
    case pollVotes(pollId: String)
    case pollVoteInMessage(messageId: MessageId, pollId: String)
    case pollVote(messageId: MessageId, pollId: String, voteId: String)

    var value: String {
        switch self {
        case .connect: return "connect"
        case .sync: return "sync"
        case .users: return "users"
        case .guest: return "guest"
        case .members: return "members"
        case .search: return "search"
        case .devices: return "devices"
        case .og: return "og"
        case .unread: return "unread"

        case .threads:
            return "threads"
        case let .thread(threadId):
            return "threads/\(threadId)"
        case let .markThreadRead(cid):
            return "channels/\(cid.apiPath)/read"
        case let .markThreadUnread(cid):
            return "channels/\(cid.apiPath)/unread"

        case .channels: return "channels"
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
        case let .channelEvent(channelId): return "channels/\(channelId)/event"
        case let .stopWatchingChannel(channelId): return "channels/\(channelId)/stop-watching"
        case let .pinnedMessages(channelId): return "channels/\(channelId)/pinned_messages"
        case let .uploadAttachment(channelId, type): return "channels/\(channelId)/\(type)"

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

        case .banMember: return "moderation/ban"
        case let .flagUser(flag): return "moderation/\(flag ? "flag" : "unflag")"
        case let .flagMessage(flag): return "moderation/\(flag ? "flag" : "unflag")"
        case let .muteUser(mute): return "moderation/\(mute ? "mute" : "unmute")"
        case .blockUser: return "users/block"
        case .unblockUser: return "users/unblock"
        case let .callToken(callId): return "calls/\(callId)"
        case let .createCall(queryString): return "channels/\(queryString)/call"
        case let .deleteFile(channelId): return "channels/\(channelId)/file"
        case let .deleteImage(channelId): return "channels/\(channelId)/image"
        case .appSettings: return "app"
        case .polls: return "polls"
        case .pollsQuery: return "polls/query"
        case let .poll(pollId: pollId): return "polls/\(pollId)"
        case let .pollOption(pollId: pollId, optionId: optionId): return "polls/\(pollId)/options/\(optionId)"
        case let .pollOptions(pollId: pollId): return "polls/\(pollId)/options"
        case let .pollVoteInMessage(messageId: messageId, pollId: pollId): return "messages/\(messageId)/polls/\(pollId)/vote"
        case let .pollVote(messageId: messageId, pollId: pollId, voteId: voteId): return "messages/\(messageId)/polls/\(pollId)/vote/\(voteId)"
        case let .pollVotes(pollId: pollId): return "polls/\(pollId)/votes"
        }
    }
}
