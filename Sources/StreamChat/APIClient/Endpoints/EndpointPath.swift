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
    case deleteChannel(String)
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
    case editMessage(MessageId)
    case deleteMessage(MessageId)
    case replies(MessageId)
    case reactions(MessageId)
    case reaction(MessageId)
    case deleteReaction(MessageId, MessageReactionType)
    case messageAction(MessageId)

    case banMember
    case flagUser(Bool)
    case flagMessage(Bool)
    case muteUser(Bool)

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
        case let .deleteChannel(payloadPath): return "channels/\(payloadPath)"
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
        case let .message(messageId): return "messages/\(messageId)"
        case let .editMessage(messageId): return "messages/\(messageId)"
        case let .deleteMessage(messageId): return "messages/\(messageId)"
        case let .replies(messageId): return "messages/\(messageId)/replies"
        case let .reactions(messageId): return "messages/\(messageId)/reactions"
        case let .reaction(messageId): return "messages/\(messageId)/reaction"
        case let .deleteReaction(messageId, reaction): return "messages/\(messageId)/reaction/\(reaction.rawValue)"
        case let .messageAction(messageId): return "messages/\(messageId)/action"

        case .banMember: return "moderation/ban"
        case let .flagUser(flag): return "moderation/\(flag ? "flag" : "unflag")"
        case let .flagMessage(flag): return "moderation/\(flag ? "flag" : "unflag")"
        case let .muteUser(mute): return "moderation/\(mute ? "mute" : "unmute")"
        }
    }

    var shouldBeQueuedOffline: Bool {
        switch self {
        case .connect: return false
        case .sync: return false
        case .users: return true // When it is a PATCH - Needs DB Action
        case .guest: return false
        case .members: return false
        case .search: return false
        case .devices: return true // When it is a POST / DELETE - Needs DB Action
        case .channels: return false
        case .channelsQuery: return true // Needs DB Action
        case .deleteChannel: return true // Needs DB Action
        case .channelUpdate: return true
        case .muteChannel: return true
        case .showChannel: return true // Needs DB Action
        case .truncateChannel: return true
        case .markChannelRead: return true // Needs DB Action
        case .markAllChannelsRead: return true
        case .channelEvent: return false
        case .stopWatchingChannel: return true
        case .pinnedMessages: return false
        case .uploadAttachment: return true // Needs DB Action
        case .sendMessage: return true // Needs DB Action
        case .message: return false
        case .editMessage: return true // Needs DB Action
        case .deleteMessage: return true // Needs DB Action
        case .replies: return false
        case .reactions: return false
        case .reaction: return true // Needs DB Action
        case .deleteReaction: return true // Needs DB Action
        case .messageAction: return true // Needs DB Action
        case .banMember: return true
        case .flagUser: return true // Needs DB Action
        case .flagMessage: return true // Needs DB Action
        case .muteUser: return false
        }
    }

    var queuedRequestNeedsDatabaseAction: Bool {
        switch self {
        case .users: return true
        case .devices: return true
        case .channelsQuery: return true
        case .deleteChannel: return true
        case .channelUpdate: return false
        case .muteChannel: return false
        case .showChannel: return true
        case .truncateChannel: return false
        case .markChannelRead: return true
        case .markAllChannelsRead: return true
        case .stopWatchingChannel: return true
        case .uploadAttachment: return true
        case .sendMessage: return true
        case .editMessage: return true
        case .deleteMessage: return true
        case .reaction: return true
        case .deleteReaction: return true
        case .messageAction: return true
        case .banMember: return false
        case .flagUser: return true
        case .flagMessage: return true
        default: return false
        }
    }
}
