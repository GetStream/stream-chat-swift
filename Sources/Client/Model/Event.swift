//
//  Event.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A web socket event type.
public enum EventType: String, Codable {
    /// Every 30 second to confirm that the client connection is still active (🗼).
    case healthCheck = "health.check"
    /// A pong event.
    case pong
    /// ⚠️ When the state of the connection changed (🗼).
    case connectionChanged = "connection.changed"
    /// ⚠️ When the connection to chat servers is back online (🗼).
    case connectionRecovered = "connection.recovered"
    
    /// When a channel was updated (when watching the channel 📺).
    case channelUpdated = "channel.updated"
    /// When a channel was deleted (when watching the channel 📺).
    case channelDeleted = "channel.deleted"
    /// When a channel was hidden (when watching the channel 📺).
    case channelHidden = "channel.hidden"
    
    /// When a user status changes, e.g. online, offline, away (when subscribed to the user status 🙋‍♀️).
    case userPresenceChanged = "user.presence.changed"
    /// When a user starts watching a channel (when watching the channel 📺).
    case userStartWatching = "user.watching.start"
    /// When a user stops watching a channel (when watching the channel 📺).
    case userStopWatching = "user.watching.stop"
    /// When a user was updated (when subscribed to the user status 🙋‍♀️).
    case userUpdated = "user.updated"
    /// When a user was banned (when subscribed to the user status 🙋‍♀️).
    case userBanned = "user.banned"
    /// Sent when a user starts typing (when watching the channel 📺).
    case typingStart = "typing.start"
    /// Sent when a user stops typing (when watching the channel 📺).
    case typingStop = "typing.stop"
    /// When a new message was added on a channel (when watching the channel 📺).
    case messageNew = "message.new"
    /// When a message was updated (when watching the channel 📺).
    case messageUpdated = "message.updated"
    /// When a message was deleted (when watching the channel 📺).
    case messageDeleted = "message.deleted"
    /// When a channel was marked as read (when watching the channel 📺).
    case messageRead = "message.read"
    /// ⚠️ When a message reaction was added or deleted (when watching the channel 📺).
    case messageReaction = "message.reaction"
    /// When a member was added to a channel (when watching the channel 📺).
    case memberAdded = "member.added"
    /// When a member was updated (when watching the channel 📺).
    case memberUpdated = "member.updated"
    /// When a member was removed from a channel (when watching the channel 📺).
    case memberRemoved = "member.removed"
    
    /// When a message was added to a channel (when clients that are not currently watching the channel ⚡️).
    case notificationMessageNew = "notification.message_new"
    /// When the user mutes someone (🙋‍♀️).
    case notificationMutesUpdated = "notification.mutes_updated"
    /// When the total count of unread messages (across all channels the user is a member) changes
    /// (when clients from the user affected by the change 📺📺).
    case notificationMarkRead = "notification.mark_read"
    
    /// When the user was invited to join a channel (when the user invited 💌).
    case notificationInvited = "notification.invited"
    /// When the user accepts an invite (when the user invited 💌).
    case notificationInviteAccepted = "notification.invite_accepted"
    /// When the user reject an invite (when the user invited 💌).
    case notificationInviteRejected = "notification.invite_rejected"
    
    /// When the user accepts an invite (when the user invited 📺).
    case notificationAddedToChannel = "notification.added_to_channel"
    /// When a user was removed from a channel (when the user invited 📺).
    case notificationRemovedFromChannel = "notification.removed_from_channel"
    
    /// When a message reaction was added.
    case reactionNew = "reaction.new"
    /// When a message reaction updated.
    case reactionUpdated = "reaction.updated"
    /// When a message reaction deleted.
    case reactionDeleted = "reaction.deleted"
}

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
        case unreadCount = "total_unread_count"
        case unreadChannels = "unread_channels"
        case created = "created_at"
        case reason
        case expiration
    }
    
    struct ResponseTypeError: Swift.Error {
        let type: EventType
    }
    
    /// A filter type for events.
    public typealias Filter = (Event, Channel?) -> Bool
    
    case healthCheck(_ connectionId: String, User)
    case pong
    
    case channelUpdated(ChannelUpdatedResponse, ChannelId?, EventType)
    case channelDeleted(Channel, EventType)
    case channelHidden(HiddenChannelResponse, ChannelId?, EventType)
    
    case messageRead(MessageRead, ChannelId?, EventType)
    case messageNew(Message, _ unreadCount: Int, _ unreadChannels: Int, Channel?, ChannelId?, EventType)
    case messageDeleted(Message, ChannelId?, EventType)
    case messageUpdated(Message, ChannelId?, EventType)
    
    case userUpdated(User, ChannelId?, EventType)
    case userPresenceChanged(User, ChannelId?, EventType)
    case userStartWatching(User, _ watcherCount: Int, ChannelId?, EventType)
    case userStopWatching(User, _ watcherCount: Int, ChannelId?, EventType)
    case userBanned(reason: String?, expiration: Date?, created: Date, ChannelId?, EventType)
    
    case memberAdded(Member, ChannelId?, EventType)
    case memberUpdated(Member, ChannelId?, EventType)
    case memberRemoved(User, ChannelId?, EventType)
    
    case reactionNew(Reaction, Message, User, ChannelId?, EventType)
    case reactionUpdated(Reaction, Message, User, ChannelId?, EventType)
    case reactionDeleted(Reaction, Message, User, ChannelId?, EventType)
    
    case typingStart(User, ChannelId?, EventType)
    case typingStop(User, ChannelId?, EventType)
    
    case notificationMutesUpdated(User, ChannelId?, EventType)
    case notificationMarkRead(Channel?, _ unreadCount: Int, _ unreadChannels: Int, ChannelId?, EventType)
    
    case notificationAddedToChannel(Channel, EventType)
    case notificationRemovedFromChannel(Channel, EventType)
    
    case notificationInvited(Channel, EventType)
    case notificationInviteAccepted(Channel, EventType)
    case notificationInviteRejected(Channel, EventType)
    
    /// An event type.
    public var type: EventType {
        switch self {
        case .healthCheck:
            return .healthCheck
            
        case .pong:
            return .pong
            
        case .channelUpdated(_, _, let type),
             .channelDeleted(_, let type),
             .channelHidden(_, _, let type),
             
             .messageRead(_, _, let type),
             .messageNew(_, _, _, _, _, let type),
             .messageDeleted(_, _, let type),
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
             
             .notificationMutesUpdated(_, _, let type),
             .notificationMarkRead(_, _, _, _, let type),
             
             .notificationAddedToChannel(_, let type),
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
        case .healthCheck, .pong:
            return nil
            
        case .channelUpdated(_, let cid, _),
             .channelHidden(_, let cid, _),
             
             .messageRead(_, let cid, _),
             .messageNew(_, _, _, _, let cid, _),
             .messageDeleted(_, let cid, _),
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
             
             .notificationMutesUpdated(_, let cid, _),
             .notificationMarkRead(_, _, _, let cid, _):
             return cid
            
        case .channelDeleted(let channel, _),
             .notificationAddedToChannel(let channel, _),
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
        case .healthCheck(_, let user),
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
        default:
            return nil
        }
    }
    
    // MARK: Decoder
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EventType.self, forKey: .type)
        
        if type == .healthCheck {
            let connectionId = try container.decode(String.self, forKey: .connectionId)
            
            if let user = try container.decodeIfPresent(User.self, forKey: .me) {
                self = .healthCheck(connectionId, user)
            } else {
                self = .pong
            }
            
            return
        }
        
        func user() throws -> User {
            return try container.decode(User.self, forKey: .user)
        }
        
        func member() throws -> Member {
            return try container.decode(Member.self, forKey: .member)
        }
        
        func channel() throws -> Channel {
            return try container.decode(Channel.self, forKey: .channel)
        }
        
        func message() throws -> Message {
            return try container.decode(Message.self, forKey: .message)
        }
        
        func reaction() throws -> Reaction {
            return try container.decode(Reaction.self, forKey: .reaction)
        }
        
        func cid() throws -> ChannelId? {
            return try container.decodeIfPresent(ChannelId.self, forKey: .cid)
        }
        
        switch type {
        // Channel
        case .channelUpdated:
            self = try .channelUpdated(ChannelUpdatedResponse(from: decoder), cid(), type)
        case .channelDeleted:
            self = try .channelDeleted(channel(), type)
        case .channelHidden:
            let hiddenChannelResponse = try HiddenChannelResponse(from: decoder)
            self = try .channelHidden(hiddenChannelResponse, cid(), type)
            
        // Message
        case .messageNew, .notificationMessageNew:
            let newMessage = try message()
            let unreadCount = try container.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0
            let unreadChannels = try container.decodeIfPresent(Int.self, forKey: .unreadChannels) ?? 0
            let channel = try container.decodeIfPresent(Channel.self, forKey: .channel)
            self = try .messageNew(newMessage, unreadCount, unreadChannels, channel, cid(), type)
        case .messageRead:
            let created = try container.decode(Date.self, forKey: .created)
            self = try .messageRead(MessageRead(user: user(), lastReadDate: created), cid(), type)
        case .messageDeleted:
            self = try .messageDeleted(message(), cid(), type)
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
            let created = try container.decode(Date.self, forKey: .created)
            self = .userBanned(reason: reason, expiration: expiration, created: created, channelId, type)
            
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
        // case .reactionUpdated:
        // self = .reactionUpdated(try reaction(), try message(), try user(), type)
        case .reactionNew:
            self = try .reactionNew(reaction(), message(), user(), cid(), type)
        case .reactionDeleted:
            self = try .reactionDeleted(reaction(), message(), user(), cid(), type)
        
        // Notifications
        case .notificationMutesUpdated:
            self = try .notificationMutesUpdated(container.decode(User.self, forKey: .me), cid(), type)
        case .notificationMarkRead:
            let unreadCount = try container.decode(Int.self, forKey: .unreadCount)
            let unreadChannels = try container.decode(Int.self, forKey: .unreadChannels)
            self = .notificationMarkRead(try? channel(), unreadCount, unreadChannels, try cid(), type)
            
        // Channel
        case .notificationAddedToChannel:
            self = try .notificationAddedToChannel(channel(), type)
        case .notificationRemovedFromChannel:
            self = try .notificationRemovedFromChannel(channel(), type)
            
        // Invites
        case .notificationInvited:
            self = try .notificationInvited(channel(), type)
        case .notificationInviteAccepted:
            self = try .notificationInviteAccepted(channel(), type)
        case .notificationInviteRejected:
            self = try .notificationInviteRejected(channel(), type)
            
        default:
            throw ResponseTypeError(type: type)
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
        case (let .messageNew(message1, unreadCount1, unreadChannels1, channel1, cid1, _),
              let .messageNew(message2, unreadCount2, unreadChannels2, channel2, cid2, _)):
            return message1 == message2
                && unreadCount1 == unreadCount2
                && unreadChannels1 == unreadChannels2
                && channel1 == channel2
                && cid1 == cid2
        case (let .messageDeleted(message1, cid1, _), let .messageDeleted(message2, cid2, _)):
            return message1 == message2 && cid1 == cid2
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
        case (let .notificationMutesUpdated(user1, cid1, _), let .notificationMutesUpdated(user2, cid2, _)):
            return user1 == user2 && cid1 == cid2
        case (let .notificationMarkRead(channel1, unreadCount1, unreadChannels1, cid1, _),
              let .notificationMarkRead(channel2, unreadCount2, unreadChannels2, cid2, _)):
            return channel1 == channel2 && unreadCount1 == unreadCount2 && unreadChannels1 == unreadChannels2 && cid1 == cid2
        case (.notificationAddedToChannel(let channel1, _), .notificationAddedToChannel(let channel2, _)),
             (.notificationRemovedFromChannel(let channel1, _), .notificationRemovedFromChannel(let channel2, _)),
             (.notificationInvited(let channel1, _), .notificationInvited(let channel2, _)),
             (.notificationInviteAccepted(let channel1, _), .notificationInviteAccepted(let channel2, _)),
             (.notificationInviteRejected(let channel1, _), .notificationInviteRejected(let channel2, _)):
            return channel1 == channel2
        default:
            return false
        }
    }
}
