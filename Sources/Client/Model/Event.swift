//
//  Event.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A web socket event.
public enum Event: Decodable {
    private enum CodingKeys: String, CodingKey {
        case connectionId = "connection_id"
        case type
        case cid
        case me
        case user
        case member
        case watcherCount = "watcher_count"
        case channel
        case channelType = "channel_type"
        case channelId = "channel_id"
        case message
        case reaction
        case unreadChannelsCount = "unread_channels"
        case unreadMessagesCount = "unread_messages"
        case totalUnreadCount = "total_unread_count"
        case created = "created_at"
        case reason
        case expiration
    }
    
    /// A filter type for events.
    public typealias Filter = (Event, Channel?) -> Bool
    
    case connectionChanged(ConnectionState)
    /// Every 30 second to confirm that the client connection is still active.
    case healthCheck(User, _ connectionId: String)
    /// A pong event.
    case pong
    
    /// When a user presence changed, e.g. online, offline, away (when subscribed to the user presence).
    case userPresenceChanged(User, ChannelId?, EventType)
    /// When a user was updated (when subscribed to the user presence).
    case userUpdated(User, ChannelId?, EventType)
    /// When a user was banned (when subscribed to the user presence).
    case userBanned(reason: String?, expiration: Date?, created: Date, ChannelId?, EventType)
    /// When a user starts watching a channel (when watching the channel).
    case userStartWatching(User, _ watcherCount: Int, ChannelId?, EventType)
    /// When a user stops watching a channel (when watching the channel).
    case userStopWatching(User, _ watcherCount: Int, ChannelId?, EventType)
    
    /// Sent when a user starts typing (when watching the channel).
    case typingStart(User, ChannelId?, EventType)
    /// Sent when a user stops typing (when watching the channel).
    case typingStop(User, ChannelId?, EventType)

    /// When a channel was updated (when watching the channel).
    case channelUpdated(ChannelUpdatedResponse, ChannelId?, EventType)
    /// When a channel was deleted (when watching the channel).
    case channelDeleted(Channel, EventType)
    /// When a channel was hidden (when watching the channel).
    case channelHidden(HiddenChannelResponse, ChannelId?, EventType)
    
    /// When a new message was added on a channel (when watching the channel).
    case messageNew(Message, _ watcherCount: Int, ChannelId?, EventType)
    /// When a message was updated (when watching the channel).
    case messageUpdated(Message, ChannelId?, EventType)
    /// When a message was deleted (when watching the channel).
    case messageDeleted(Message, User?, ChannelId?, EventType)
    /// When a channel was marked as read (when watching the channel).
    case messageRead(MessageRead, ChannelId?, EventType)
    
    /// When a member was added to a channel (when watching the channel).
    case memberAdded(Member, ChannelId?, EventType)
    /// When a member was updated (when watching the channel).
    case memberUpdated(Member, ChannelId?, EventType)
    /// When a member was removed from a channel (when watching the channel).
    case memberRemoved(User, ChannelId?, EventType)
    
    /// When a message reaction was added.
    case reactionNew(Reaction, Message, User, ChannelId?, EventType)
    /// When a message reaction updated.
    case reactionUpdated(Reaction, Message, User, ChannelId?, EventType)
    /// When a message reaction deleted.
    case reactionDeleted(Reaction, Message, User, ChannelId?, EventType)
    
    /// When a new message was added on a channel (when clients that are not currently watching the channel).
    case notificationMessageNew(Message, Channel, UnreadCount, _ watcherCount: Int, EventType)
    /// When the count of unread messages changed for the channel where the user is a member.
    case notificationMarkRead(MessageRead, Channel, UnreadCount, EventType)
    /// When the total count of unread messages (across all channels the user is a member) changed
    /// (when clients from the user affected by the change).
    case notificationMarkAllRead(MessageRead, EventType)
    /// When the user mutes someone.
    case notificationMutesUpdated(User, ChannelId?, EventType)
    
    /// When the user accepts an invite (when the user invited).
    case notificationAddedToChannel(Channel, UnreadCount, EventType)
    /// When a user was removed from a channel (when the user invited).
    case notificationRemovedFromChannel(Channel, EventType)
    
    /// When the user was invited to join a channel (when the user invited).
    case notificationInvited(Channel, EventType)
    /// When the user accepts an invite (when the user invited).
    case notificationInviteAccepted(Channel, EventType)
    /// When the user reject an invite (when the user invited).
    case notificationInviteRejected(Channel, EventType)
    
    /// An event type.
    public var type: EventType {
        switch self {
        case .connectionChanged:
            return .connectionChanged
        case .healthCheck:
            return .healthCheck
        case .pong:
            return .pong
            
        case .channelUpdated(_, _, let type),
             .channelDeleted(_, let type),
             .channelHidden(_, _, let type),
             
             .messageRead(_, _, let type),
             .messageNew(_, _, _, let type),
             .messageDeleted(_, _, _, let type),
             .messageUpdated(_, _, let type),
             
             .userUpdated(_, _, let type),
             .userPresenceChanged(_, _, let type),
             .userStartWatching(_, _, _, let type),
             .userStopWatching(_, _, _, let type),
             .userBanned(_, _, _, _, let type),
             
             .memberAdded(_, _, let type),
             .memberUpdated(_, _, let type),
             .memberRemoved(_, _, let type),
             
             .reactionNew(_, _, _, _, let type),
             .reactionUpdated(_, _, _, _, let type),
             .reactionDeleted(_, _, _, _, let type),
             
             .typingStart(_, _, let type),
             .typingStop(_, _, let type),
             
             .notificationMessageNew(_, _, _, _, let type),
             .notificationMarkRead(_, _, _, let type),
             .notificationMarkAllRead(_, let type),
             .notificationMutesUpdated(_, _, let type),

             .notificationAddedToChannel(_, _, let type),
             .notificationRemovedFromChannel(_, let type),
             
             .notificationInvited(_, let type),
             .notificationInviteAccepted(_, let type),
             .notificationInviteRejected(_, let type):
            return type
        }
    }
    
    /// A cid from the event.
    public var cid: ChannelId? {
        switch self {
        case .connectionChanged,
             .healthCheck,
             .pong,
             .notificationMarkAllRead:
            return nil
            
        case .channelUpdated(_, let cid, _),
             .channelHidden(_, let cid, _),
             
             .messageRead(_, let cid, _),
             .messageNew(_, _, let cid, _),
             .messageDeleted(_, _, let cid, _),
             .messageUpdated(_, let cid, _),
             
             .userUpdated(_, let cid, _),
             .userPresenceChanged(_, let cid, _),
             .userStartWatching(_, _, let cid, _),
             .userStopWatching(_, _, let cid, _),
             .userBanned(_, _, _, let cid, _),
             
             .memberAdded(_, let cid, _),
             .memberUpdated(_, let cid, _),
             .memberRemoved(_, let cid, _),
             
             .reactionNew(_, _, _, let cid, _),
             .reactionUpdated(_, _, _, let cid, _),
             .reactionDeleted(_, _, _, let cid, _),
             
             .typingStart(_, let cid, _),
             .typingStop(_, let cid, _),
             
             .notificationMutesUpdated(_, let cid, _):
             return cid
            
        case .channelDeleted(let channel, _),
             .notificationMessageNew(_, let channel, _, _, _),
             .notificationMarkRead(_, let channel, _, _),
             .notificationAddedToChannel(let channel, _, _),
             .notificationRemovedFromChannel(let channel, _),
             .notificationInvited(let channel, _),
             .notificationInviteAccepted(let channel, _),
             .notificationInviteRejected(let channel, _):
            return channel.cid
        }
    }
    
    /// A user from the event.
    public var user: User? {
        switch self {
        case .healthCheck(let user, _),
             .userUpdated(let user, _, _),
             .userPresenceChanged(let user, _, _),
             .userStartWatching(let user, _, _, _),
             .userStopWatching(let user, _, _, _),
             .memberRemoved(let user, _, _),
             .reactionNew(_, _, let user, _, _),
             .reactionUpdated(_, _, let user, _, _),
             .reactionDeleted(_, _, let user, _, _),
             .typingStart(let user, _, _),
             .typingStop(let user, _, _),
             .notificationMutesUpdated(let user, _, _):
            return user
        case .memberAdded(let member, _, _),
             .memberUpdated(let member, _, _):
            return member.user
        case .messageNew(let message, _, _, _),
             .notificationMessageNew(let message, _, _, _, _):
            return message.user
        default:
            return nil
        }
    }
    
    public var isNotification: Bool {
        switch self {
        case .notificationMarkAllRead,
             .notificationMarkRead,
             .notificationMessageNew,
             .notificationMutesUpdated,
             .notificationAddedToChannel,
             .notificationRemovedFromChannel,
             .notificationInvited,
             .notificationInviteAccepted,
             .notificationInviteRejected:
            return true
        default:
            return false
        }
    }
    
    // MARK: Decoder
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EventType.self, forKey: .type)
        
        func user() throws -> User {
            try container.decode(User.self, forKey: .user)
        }
        
        func optionalUser() throws -> User? {
            try container.decodeIfPresent(User.self, forKey: .user)
        }
        
        func member() throws -> Member {
            try container.decode(Member.self, forKey: .member)
        }
        
        func channel() throws -> Channel {
            try container.decode(Channel.self, forKey: .channel)
        }
        
        func optionalChannel() throws -> Channel? {
            try container.decodeIfPresent(Channel.self, forKey: .channel)
        }
        
        func message() throws -> Message {
            try container.decode(Message.self, forKey: .message)
        }
        
        func reaction() throws -> Reaction {
            try container.decode(Reaction.self, forKey: .reaction)
        }
        
        func cid() throws -> ChannelId? {
            try container.decodeIfPresent(ChannelId.self, forKey: .cid)
        }
        
        func created() throws -> Date {
            try container.decode(Date.self, forKey: .created)
        }
        
        func unreadCount() throws -> UnreadCount {
            let unreadChannelsCount = try container.decodeIfPresent(Int.self, forKey: .unreadChannelsCount) ?? 0
            let totalUnreadCount = try container.decodeIfPresent(Int.self, forKey: .totalUnreadCount) ?? 0
            return UnreadCount(channels: unreadChannelsCount, messages: totalUnreadCount)
        }
        
        switch type {
        case .connectionChanged:
            self = .connectionChanged(.notConnected)
        case .healthCheck:
            let connectionId = try container.decode(String.self, forKey: .connectionId)
            
            if let user = try container.decodeIfPresent(User.self, forKey: .me) {
                self = .healthCheck(user, connectionId)
            } else {
                self = .pong
            }
        case .pong:
            self = .pong
            
        // Channel
        case .channelUpdated:
            self = try .channelUpdated(ChannelUpdatedResponse(from: decoder), cid(), type)
        case .channelDeleted:
            self = try .channelDeleted(channel(), type)
        case .channelHidden:
            let hiddenChannelResponse = try HiddenChannelResponse(from: decoder)
            self = try .channelHidden(hiddenChannelResponse, cid(), type)
            
        // Message
        case .messageNew:
            let watcherCount = try container.decodeIfPresent(Int.self, forKey: .watcherCount) ?? 0
            self = try .messageNew(message(), watcherCount, cid(), type)
        case .messageRead:
            let unreadMessages = try container.decodeIfPresent(Int.self, forKey: .unreadMessagesCount) ?? 0
            let messageRead = try MessageRead(user: user(), lastReadDate: created(), unreadMessagesCount: unreadMessages)
            self = try .messageRead(messageRead, cid(), type)
        case .messageDeleted:
            self = try .messageDeleted(message(), optionalUser(), cid(), type)
        case .messageUpdated:
            self = try .messageUpdated(message(), cid(), type)
            
        // User
        case .userUpdated:
            self = try .userUpdated(user(), cid(), type)
        case .userPresenceChanged:
            self = try .userPresenceChanged(user(), cid(), type)
        case .userStartWatching:
            let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
            self = try .userStartWatching(user(), watcherCount, cid(), type)
        case .userStopWatching:
            let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
            self = try .userStopWatching(user(), watcherCount, cid(), type)
        case .userBanned:
            var channelId: ChannelId? = try? cid()
            
            if let channelType = try container.decodeIfPresent(ChannelType.self, forKey: .channelType),
                let id = try container.decodeIfPresent(String.self, forKey: .channelId) {
                channelId = ChannelId(type: channelType, id: id)
            }
            
            let reason = try container.decodeIfPresent(String.self, forKey: .reason)
            let expiration = try container.decodeIfPresent(Date.self, forKey: .expiration)
            self = try .userBanned(reason: reason, expiration: expiration, created: created(), channelId, type)
            
        // Member
        case .memberAdded:
            self = try .memberUpdated(member(), cid(), type)
        case .memberUpdated:
            self = try .memberUpdated(member(), cid(), type)
        case .memberRemoved:
            self = try .memberRemoved(user(), cid(), type)
            
        // Typing
        case .typingStart:
            self = try .typingStart(user(), cid(), type)
        case .typingStop:
            self = try .typingStop(user(), cid(), type)
            
        // Reaction
        case .reactionNew:
            self = try .reactionNew(reaction(), message(), user(), cid(), type)
        case .reactionUpdated:
            self = try .reactionUpdated(reaction(), message(), user(), cid(), type)
        case .reactionDeleted:
            self = try .reactionDeleted(reaction(), message(), user(), cid(), type)
        
        // Notifications
        case .notificationMutesUpdated:
            self = try .notificationMutesUpdated(container.decode(User.self, forKey: .me), cid(), type)
        case .notificationMarkRead:
            let messageRead = try MessageRead(user: .current, lastReadDate: created(), unreadMessagesCount: 0)
            
            if let channel = try optionalChannel() {
                self = try .notificationMarkRead(messageRead, channel, unreadCount(), type)
            } else {
                self = .notificationMarkAllRead(messageRead, type)
            }
        case .notificationAddedToChannel:
            self = try .notificationAddedToChannel(channel(), unreadCount(), type)
        case .notificationRemovedFromChannel:
            self = try .notificationRemovedFromChannel(channel(), type)
        case .notificationMessageNew:
            let watcherCount = try container.decodeIfPresent(Int.self, forKey: .watcherCount) ?? 0
            self = try .notificationMessageNew(message(), channel(), unreadCount(), watcherCount, type)
            
        // Invites
        case .notificationInvited:
            self = try .notificationInvited(channel(), type)
        case .notificationInviteAccepted:
            self = try .notificationInviteAccepted(channel(), type)
        case .notificationInviteRejected:
            self = try .notificationInviteRejected(channel(), type)
        }
    }
}

// MARK: - Equatable

extension Event: Equatable {
    public static func == (lhs: Event, rhs: Event) -> Bool {
        switch (lhs, rhs) {
        case (.healthCheck, .healthCheck), (.pong, .pong):
            return true
        case (let .channelUpdated(response1, cid1, _), let .channelUpdated(response2, cid2, _)):
            return response1 == response2 && cid1 == cid2
        case (.channelDeleted(let channel1, _), .channelDeleted(let channel2, _)):
            return channel1 == channel2
        case (let .channelHidden(hiddenChannelResponse1, cid1, _), let .channelHidden(hiddenChannelResponse2, cid2, _)):
            return hiddenChannelResponse1 == hiddenChannelResponse2 && cid1 == cid2
        case (let .messageRead(messageRead1, cid1, _), let .messageRead(messageRead2, cid2, _)):
            return messageRead1 == messageRead2 && cid1 == cid2
        case (let .messageNew(message1, watcherCount1, cid1, _), let .messageNew(message2, watcherCount2, cid2, _)):
            return message1 == message2 && watcherCount1 == watcherCount2 && cid1 == cid2
        case (let .messageDeleted(message1, user1, cid1, _), let .messageDeleted(message2, user2, cid2, _)):
            return message1 == message2 && user1 == user2 && cid1 == cid2
        case (let .messageUpdated(message1, cid1, _), let .messageUpdated(message2, cid2, _)):
            return message1 == message2 && cid1 == cid2
        case (let .userUpdated(user1, cid1, _), let .userUpdated(user2, cid2, _)):
            return user1 == user2 && cid1 == cid2
        case (let .userPresenceChanged(user1, cid1, _), let .userPresenceChanged(user2, cid2, _)):
            return user1 == user2 && cid1 == cid2
        case (let .userStartWatching(user1, watcherCount1, cid1, _), let .userStartWatching(user2, watcherCount2, cid2, _)):
            return user1 == user2 && watcherCount1 == watcherCount2 && cid1 == cid2
        case (let .userStopWatching(user1, watcherCount1, cid1, _), let .userStopWatching(user2, watcherCount2, cid2, _)):
            return user1 == user2 && watcherCount1 == watcherCount2 && cid1 == cid2
        case (let .userBanned(reason1, expiration1, created1, cid1, _), let .userBanned(reason2, expiration2, created2, cid2, _)):
            return reason1 == reason2 && expiration1 == expiration2 && created1 == created2 && cid1 == cid2
        case (let .memberAdded(member1, cid1, _), let .memberAdded(member2, cid2, _)):
            return member1 == member2 && cid1 == cid2
        case (let .memberUpdated(member1, cid1, _), let .memberUpdated(member2, cid2, _)):
            return member1 == member2 && cid1 == cid2
        case (let .memberRemoved(user1, cid1, _), let .memberRemoved(user2, cid2, _)):
            return user1 == user2 && cid1 == cid2
        case (let .reactionNew(reaction1, message1, user1, cid1, _), let .reactionNew(reaction2, message2, user2, cid2, _)):
            return reaction1 == reaction2 && message1 == message2 && user1 == user2 && cid1 == cid2
        case (let .reactionUpdated(reaction1, message1, user1, cid1, _), let .reactionUpdated(reaction2, message2, user2, cid2, _)):
            return reaction1 == reaction2 && message1 == message2 && user1 == user2 && cid1 == cid2
        case (let .reactionDeleted(reaction1, message1, user1, cid1, _), let .reactionDeleted(reaction2, message2, user2, cid2, _)):
            return reaction1 == reaction2 && message1 == message2 && user1 == user2 && cid1 == cid2
        case (let .typingStart(user1, cid1, _), let .typingStart(user2, cid2, _)):
            return user1 == user2 && cid1 == cid2
        case (let .typingStop(user1, cid1, _), let .typingStop(user2, cid2, _)):
            return user1 == user2 && cid1 == cid2
        case (let .notificationMessageNew(message1, channel1, unreadCount1, watcherCount1, _),
              let .notificationMessageNew(message2, channel2, unreadCount2, watcherCount2, _)):
            return message1 == message2 && channel1 == channel2 && unreadCount1 == unreadCount2 && watcherCount1 == watcherCount2
        case (let .notificationMutesUpdated(user1, cid1, _), let .notificationMutesUpdated(user2, cid2, _)):
            return user1 == user2 && cid1 == cid2
        case (let .notificationMarkAllRead(created1, _), let .notificationMarkAllRead(created2, _)):
            return created1 == created2
        case (let .notificationMarkRead(messageRead1, channel1, unreadCount1, _),
              let .notificationMarkRead(messageRead2, channel2, unreadCount2, _)):
            return messageRead1 == messageRead2 && channel1 == channel2 && unreadCount1 == unreadCount2
        case (let .notificationAddedToChannel(channel1, unreadCount1, _),
              let .notificationAddedToChannel(channel2, unreadCount2, _)):
            return channel1 == channel2 && unreadCount1 == unreadCount2
        case (.notificationRemovedFromChannel(let channel1, _), .notificationRemovedFromChannel(let channel2, _)),
             (.notificationInvited(let channel1, _), .notificationInvited(let channel2, _)),
             (.notificationInviteAccepted(let channel1, _), .notificationInviteAccepted(let channel2, _)),
             (.notificationInviteRejected(let channel1, _), .notificationInviteRejected(let channel2, _)):
            return channel1 == channel2
        default:
            return false
        }
    }
}
