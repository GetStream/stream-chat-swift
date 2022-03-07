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
    case createChannel(String)
    case updateChannel(String)
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
    case uploadAttachment(channelId: String, type: String)

    case sendMessage(ChannelId)
    case message(MessageId)
    case editMessage(MessageId)
    case deleteMessage(MessageId)
    case replies(MessageId)
    case reactions(MessageId)
    case addReaction(MessageId)
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
        case let .createChannel(queryString): return "channels/\(queryString)/query"
        case let .updateChannel(queryString): return "channels/\(queryString)/query"
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

        case let .sendMessage(channelId): return "channels/\(channelId.apiPath)/message"
        case let .message(messageId): return "messages/\(messageId)"
        case let .editMessage(messageId): return "messages/\(messageId)"
        case let .deleteMessage(messageId): return "messages/\(messageId)"
        case let .replies(messageId): return "messages/\(messageId)/replies"
        case let .reactions(messageId): return "messages/\(messageId)/reactions"
        case let .addReaction(messageId): return "messages/\(messageId)/reaction"
        case let .deleteReaction(messageId, reaction): return "messages/\(messageId)/reaction/\(reaction.rawValue)"
        case let .messageAction(messageId): return "messages/\(messageId)/action"

        case .banMember: return "moderation/ban"
        case let .flagUser(flag): return "moderation/\(flag ? "flag" : "unflag")"
        case let .flagMessage(flag): return "moderation/\(flag ? "flag" : "unflag")"
        case let .muteUser(mute): return "moderation/\(mute ? "mute" : "unmute")"
        }
    }

    #if swift(<5.5)
    // Only needed when compiling against 5.4 or lower
    enum CodingKeys: CodingKey {
        case connect, sync, users, guest, members, search, devices, channels, createChannel, updateChannel, deleteChannel,
             channelUpdate, muteChannel, showChannel, truncateChannel, markChannelRead, markAllChannelsRead, channelEvent,
             stopWatchingChannel, pinnedMessages, uploadAttachment, sendMessage, message, editMessage, deleteMessage, replies,
             reactions, addReaction, deleteReaction, messageAction, banMember, flagUser, flagMessage, muteUser
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = container.allKeys.first else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unable to decode EndpointPath"
                )
            )
        }

        switch key {
        case .connect:
            self = .connect
        case .sync:
            self = .sync
        case .users:
            self = .users
        case .guest:
            self = .guest
        case .members:
            self = .members
        case .search:
            self = .search
        case .devices:
            self = .devices
        case .channels:
            self = .channels
        case .createChannel:
            self = try .createChannel(container.decode(String.self, forKey: key))
        case .updateChannel:
            self = try .updateChannel(container.decode(String.self, forKey: key))
        case .deleteChannel:
            self = try .deleteChannel(container.decode(String.self, forKey: key))
        case .channelUpdate:
            self = try .channelUpdate(container.decode(String.self, forKey: key))
        case .muteChannel:
            self = try .muteChannel(container.decode(Bool.self, forKey: key))
        case .showChannel:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: key)
            self = try .showChannel(
                nestedContainer.decode(String.self),
                nestedContainer.decode(Bool.self)
            )
        case .truncateChannel:
            self = try .truncateChannel(container.decode(String.self, forKey: key))
        case .markChannelRead:
            self = try .markChannelRead(container.decode(String.self, forKey: key))
        case .markAllChannelsRead:
            self = .markAllChannelsRead
        case .channelEvent:
            self = try .channelEvent(container.decode(String.self, forKey: key))
        case .stopWatchingChannel:
            self = try .stopWatchingChannel(container.decode(String.self, forKey: key))
        case .pinnedMessages:
            self = try .pinnedMessages(container.decode(String.self, forKey: key))
        case .uploadAttachment:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: key)
            self = try .uploadAttachment(
                channelId: nestedContainer.decode(String.self),
                type: nestedContainer.decode(String.self)
            )
        case .sendMessage:
            self = try .sendMessage(container.decode(ChannelId.self, forKey: key))
        case .message:
            self = try .message(container.decode(MessageId.self, forKey: key))
        case .editMessage:
            self = try .editMessage(container.decode(MessageId.self, forKey: key))
        case .deleteMessage:
            self = try .deleteMessage(container.decode(MessageId.self, forKey: key))
        case .replies:
            self = try .replies(container.decode(MessageId.self, forKey: key))
        case .reactions:
            self = try .reactions(container.decode(MessageId.self, forKey: key))
        case .addReaction:
            self = try .addReaction(container.decode(MessageId.self, forKey: key))
        case .deleteReaction:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: key)
            self = try .deleteReaction(
                nestedContainer.decode(MessageId.self),
                nestedContainer.decode(MessageReactionType.self)
            )
        case .messageAction:
            self = try .messageAction(container.decode(MessageId.self, forKey: key))
        case .banMember:
            self = .banMember
        case .flagUser:
            self = try .flagUser(container.decode(Bool.self, forKey: key))
        case .flagMessage:
            self = try .flagMessage(container.decode(Bool.self, forKey: key))
        case .muteUser:
            self = try .muteUser(container.decode(Bool.self, forKey: key))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .connect:
            try container.encode(true, forKey: .connect)
        case .sync:
            try container.encode(true, forKey: .sync)
        case .users:
            try container.encode(true, forKey: .users)
        case .guest:
            try container.encode(true, forKey: .guest)
        case .members:
            try container.encode(true, forKey: .members)
        case .search:
            try container.encode(true, forKey: .search)
        case .devices:
            try container.encode(true, forKey: .devices)
        case .channels:
            try container.encode(true, forKey: .channels)
        case let .createChannel(string):
            try container.encode(string, forKey: .createChannel)
        case let .updateChannel(string):
            try container.encode(string, forKey: .updateChannel)
        case let .deleteChannel(string):
            try container.encode(string, forKey: .deleteChannel)
        case let .channelUpdate(string):
            try container.encode(string, forKey: .channelUpdate)
        case let .muteChannel(bool):
            try container.encode(bool, forKey: .muteChannel)
        case let .showChannel(channelPath, show):
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .showChannel)
            try nestedContainer.encode(channelPath)
            try nestedContainer.encode(show)
        case let .truncateChannel(string):
            try container.encode(string, forKey: .truncateChannel)
        case let .markChannelRead(string):
            try container.encode(string, forKey: .markChannelRead)
        case .markAllChannelsRead:
            try container.encode(true, forKey: .markAllChannelsRead)
        case let .channelEvent(string):
            try container.encode(string, forKey: .channelEvent)
        case let .stopWatchingChannel(string):
            try container.encode(string, forKey: .stopWatchingChannel)
        case let .pinnedMessages(string):
            try container.encode(string, forKey: .pinnedMessages)
        case let .uploadAttachment(channelId, type):
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .uploadAttachment)
            try nestedContainer.encode(channelId)
            try nestedContainer.encode(type)
        case let .sendMessage(channelId):
            try container.encode(channelId, forKey: .sendMessage)
        case let .message(messageId):
            try container.encode(messageId, forKey: .message)
        case let .editMessage(messageId):
            try container.encode(messageId, forKey: .editMessage)
        case let .deleteMessage(messageId):
            try container.encode(messageId, forKey: .deleteMessage)
        case let .replies(messageId):
            try container.encode(messageId, forKey: .replies)
        case let .reactions(messageId):
            try container.encode(messageId, forKey: .reactions)
        case let .addReaction(messageId):
            try container.encode(messageId, forKey: .addReaction)
        case let .deleteReaction(messageId, reactionType):
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .deleteReaction)
            try nestedContainer.encode(messageId)
            try nestedContainer.encode(reactionType)
        case let .messageAction(messageId):
            try container.encode(messageId, forKey: .messageAction)
        case .banMember:
            try container.encode(true, forKey: .banMember)
        case let .flagUser(bool):
            try container.encode(bool, forKey: .flagUser)
        case let .flagMessage(bool):
            try container.encode(bool, forKey: .flagMessage)
        case let .muteUser(bool):
            try container.encode(bool, forKey: .muteUser)
        }
    }
    #endif
}
