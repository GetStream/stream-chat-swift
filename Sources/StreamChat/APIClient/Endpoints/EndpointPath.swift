//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

    case channels
    case channelsQuery(String)
    case channelUpdate(String)
    case muteChannel(Bool)
    case showChannel(String, Bool)
    case truncateChannel(String)
    case markChannelRead(String)
    case markAllChannelsRead
    case channelEvent(String)
    case stopWatchingChannel(String)
    case pinnedMessages(String)
    case uploadAttachment(String, String)

    case sendMessage(String)
    case message(MessageId)
    case replies(MessageId)
    case reactions(MessageId)
    case reaction(MessageId)
    case deleteReaction(MessageId, MessageReactionType)
    case action(MessageId)

    case moderationBan
    case moderationFlag(Bool)
    case moderationMute(Bool)

    var value: String {
        switch self {
        case .connect: return "connect"
        case .sync: return "sync"
        case .users: return "users"
        case .guest: return "guest"
        case .members: return "members"
        case .search: return "search"
        case .devices: return "devices"

        case .channels: return "channels"
        case let .channelsQuery(queryString): return "channels/\(queryString)/query"
        case let .channelUpdate(payloadPath): return "channels/\(payloadPath)"
        case let .muteChannel(mute): return "moderation/\(mute ? "mute" : "unmute")/channel"
        case let .showChannel(channelId, show): return "channels/\(channelId)/\(show ? "show" : "hide")"
        case let .truncateChannel(channelId): return "channels/\(channelId)/truncate"
        case let .markChannelRead(channelId): return "channels/\(channelId)/read"
        case .markAllChannelsRead: return "channels/read"
        case let .channelEvent(channelId): return "channels/\(channelId)/event"
        case let .stopWatchingChannel(channelId): return "channels/\(channelId)/stop-watching"
        case let .pinnedMessages(channelId): return "channels/\(channelId)/pinned_messages"
        case let .uploadAttachment(channelId, type): return "channels/\(channelId)/\(type)"

        case let .sendMessage(channelId): return "channels/\(channelId)/message"
        case let .message(messageId): return "messages/\(messageId)/"
        case let .replies(messageId): return "messages/\(messageId)/replies"
        case let .reactions(messageId): return "messages/\(messageId)/reactions"
        case let .reaction(messageId): return "messages/\(messageId)/reaction"
        case let .deleteReaction(messageId, reaction): return "messages/\(messageId)/reaction/\(reaction.rawValue)"
        case let .action(messageId): return "messages/\(messageId)/action"

        case .moderationBan: return "moderation/ban"
        case let .moderationFlag(flag): return "moderation/\(flag ? "flag" : "unflag")"
        case let .moderationMute(mute): return "moderation/\(mute ? "mute" : "unmute")"
        }
    }
}
