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
    
    case healthCheck(_ connectionId: String, User?)
    
    case channelUpdated(ChannelUpdatedResponse, EventType)
    case channelDeleted(Channel, EventType)
    case channelHidden(HiddenChannelResponse, EventType)
    
    case messageRead(MessageRead, EventType)
    case messageNew(Message, _ unreadCount: Int, _ unreadChannels: Int, Channel?, EventType)
    case messageDeleted(Message, EventType)
    case messageUpdated(Message, EventType)
    
    case userUpdated(User, EventType)
    case userPresenceChanged(User, EventType)
    case userStartWatching(User, _ watcherCount: Int, EventType)
    case userStopWatching(User, _ watcherCount: Int, EventType)
    case userBanned(ChannelId?, reason: String?, expiration: Date?, created: Date, EventType)
    
    case memberAdded(Member, EventType)
    case memberUpdated(Member, EventType)
    case memberRemoved(User, EventType)
    
    case reactionNew(Reaction, Message, User, EventType)
    case reactionUpdated(Reaction, Message, User, EventType)
    case reactionDeleted(Reaction, Message, User, EventType)
    
    case typingStart(User, EventType)
    case typingStop(User, EventType)
    
    case notificationMutesUpdated(User, EventType)
    case notificationMarkRead(Channel?, _ unreadCount: Int, _ unreadChannels: Int, EventType)
    
    case notificationAddedToChannel(Channel, EventType)
    case notificationRemovedFromChannel(Channel, EventType)
    
    case notificationInvited(Channel, EventType)
    case notificationInviteAccepted(Channel, EventType)
    case notificationInviteRejected(Channel, EventType)
    
    /// An event type.
    public var type: EventType {
        switch self {
        case .channelUpdated(_, let type),
             .channelDeleted(_, let type),
             .channelHidden(_, let type),
             
             .messageRead(_, let type),
             .messageNew(_, _, _, _, let type),
             .messageDeleted(_, let type),
             .messageUpdated(_, let type),
             
             .userUpdated(_, let type),
             .userPresenceChanged(_, let type),
             .userStartWatching(_, _, let type),
             .userStopWatching(_, _, let type),
             .userBanned(_, _, _, _, let type),
             
             .memberAdded(_, let type),
             .memberUpdated(_, let type),
             .memberRemoved(_, let type),
             
             .reactionNew(_, _, _, let type),
             .reactionUpdated(_, _, _, let type),
             .reactionDeleted(_, _, _, let type),
             
             .typingStart(_, let type),
             .typingStop(_, let type),
             
             .notificationMutesUpdated(_, let type),
             .notificationMarkRead(_, _, _, let type),
             
             .notificationAddedToChannel(_, let type),
             .notificationRemovedFromChannel(_, let type),
             
             .notificationInvited(_, let type),
             .notificationInviteAccepted(_, let type),
             .notificationInviteRejected(_, let type):
            return type
            
        case .healthCheck:
            return .healthCheck
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EventType.self, forKey: .type)
        
        if type == .healthCheck {
            let connectionId = try container.decode(String.self, forKey: .connectionId)
            let user = try container.decodeIfPresent(User.self, forKey: .me)
            self = .healthCheck(connectionId, user)
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
        
        switch type {
        // Channel
        case .channelUpdated:
            self = .channelUpdated(try ChannelUpdatedResponse(from: decoder), type)
        case .channelDeleted:
            self = .channelDeleted(try channel(), type)
        case .channelHidden:
            let hiddenChannelResponse = try HiddenChannelResponse(from: decoder)
            self = .channelHidden(hiddenChannelResponse, type)
            
        // Message
        case .messageNew, .notificationMessageNew:
            let newMessage = try message()
            let unreadCount = try container.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0
            let unreadChannels = try container.decodeIfPresent(Int.self, forKey: .unreadChannels) ?? 0
            let channel = try container.decodeIfPresent(Channel.self, forKey: .channel)
            self = .messageNew(newMessage, unreadCount, unreadChannels, channel, type)
        case .messageRead:
            let created = try container.decode(Date.self, forKey: .created)
            self = .messageRead(MessageRead(user: try user(), lastReadDate: created), type)
        case .messageDeleted:
            self = .messageDeleted(try message(), type)
        case .messageUpdated:
            self = .messageUpdated(try message(), type)
            
        // User
        case .userUpdated:
            self = .userUpdated(try user(), type)
        case .userPresenceChanged:
            self = .userPresenceChanged(try user(), type)
        case .userStartWatching:
            let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
            self = .userStartWatching(try user(), watcherCount, type)
        case .userStopWatching:
            let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
            self = .userStopWatching(try user(), watcherCount, type)
        case .userBanned:
            var channelId: ChannelId?
            
            if let channelType = try container.decodeIfPresent(ChannelType.self, forKey: .channelType),
                let id = try container.decodeIfPresent(String.self, forKey: .channelId) {
                channelId = ChannelId(type: channelType, id: id)
            }
            
            let reason = try container.decodeIfPresent(String.self, forKey: .reason)
            let expiration = try container.decodeIfPresent(Date.self, forKey: .expiration)
            let created = try container.decode(Date.self, forKey: .created)
            self = .userBanned(channelId, reason: reason, expiration: expiration, created: created, type)
            
        // Member
        case .memberAdded:
            self = .memberUpdated(try member(), type)
        case .memberUpdated:
            self = .memberUpdated(try member(), type)
        case .memberRemoved:
            self = .memberRemoved(try user(), type)
                
        // Typing
        case .typingStart:
            self = .typingStart(try user(), type)
        case .typingStop:
            self = .typingStop(try user(), type)
            
        // Reaction
        case .reactionNew:
            self = .reactionNew(try reaction(), try message(), try user(), type)
        case .reactionUpdated:
            self = .reactionUpdated(try reaction(), try message(), try user(), type)
        case .reactionDeleted:
            self = .reactionDeleted(try reaction(), try message(), try user(), type)
            
        // Notifications
        case .notificationMutesUpdated:
            self = .notificationMutesUpdated(try container.decode(User.self, forKey: .me), type)
        case .notificationMarkRead:
            let unreadCount = try container.decode(Int.self, forKey: .unreadCount)
            let unreadChannels = try container.decode(Int.self, forKey: .unreadChannels)
            self = .notificationMarkRead(try? channel(), unreadCount, unreadChannels, type)
            
        // Channel
        case .notificationAddedToChannel:
            self = .notificationAddedToChannel(try channel(), type)
        case .notificationRemovedFromChannel:
            self = .notificationRemovedFromChannel(try channel(), type)
            
        // Invites
        case .notificationInvited:
            self = .notificationInvited(try channel(), type)
        case .notificationInviteAccepted:
            self = .notificationInviteAccepted(try channel(), type)
        case .notificationInviteRejected:
            self = .notificationInviteRejected(try channel(), type)
            
        default:
            throw ResponseTypeError(type: type)
        }
    }
}

extension Event: Equatable {
    public static func == (lhs: Event, rhs: Event) -> Bool {
        switch (lhs, rhs) {
        case (.healthCheck, .healthCheck):
            return true
        case (.channelUpdated(let response1, _), .channelUpdated(let response2, _)):
            return response1 == response2
        case (.channelDeleted(let channel1, _), .channelDeleted(let channel2, _)):
            return channel1 == channel2
        case (.channelHidden(let hiddenChannelResponse1, _), .channelHidden(let hiddenChannelResponse2, _)):
            return hiddenChannelResponse1 == hiddenChannelResponse2
        case (.messageRead(let messageRead1, _), .messageRead(let messageRead2, _)):
            return messageRead1 == messageRead2
        case (.messageNew(let message1, let unreadCount1, let unreadChannels1, let channel1, _),
              .messageNew(let message2, let unreadCount2, let unreadChannels2, let channel2, _)):
            return message1 == message2
                && unreadCount1 == unreadCount2
                && unreadChannels1 == unreadChannels2
                && channel1 == channel2
        case (.messageDeleted(let message1, _), .messageDeleted(let message2, _)):
            return message1 == message2
        case (.messageUpdated(let message1, _), .messageUpdated(let message2, _)):
            return message1 == message2
        case (.userUpdated(let user1, _), .userUpdated(let user2, _)):
            return user1 == user2
        case (.userPresenceChanged(let user1, _), .userPresenceChanged(let user2, _)):
            return user1 == user2
        case (.userStartWatching(let user1, let watcherCount1, _), .userStartWatching(let user2, let watcherCount2, _)):
            return user1 == user2 && watcherCount1 == watcherCount2
        case (.userStopWatching(let user1, let watcherCount1, _), .userStopWatching(let user2, let watcherCount2, _)):
            return user1 == user2 && watcherCount1 == watcherCount2
        case (.memberAdded(let member1, _), .memberAdded(let member2, _)):
            return member1 == member2
        case (.memberUpdated(let member1, _), .memberUpdated(let member2, _)):
            return member1 == member2
        case (.memberRemoved(let user1, _), .memberRemoved(let user2, _)):
            return user1 == user2
        case (.reactionNew(let reaction1, let message1, let user1, _), .reactionNew(let reaction2, let message2, let user2, _)):
            return reaction1 == reaction2 && message1 == message2 && user1 == user2
        case (.reactionUpdated(let reaction1, let message1, let user1, _),
              .reactionUpdated(let reaction2, let message2, let user2, _)):
            return reaction1 == reaction2 && message1 == message2 && user1 == user2
        case (.reactionDeleted(let reaction1, let message1, let user1, _),
              .reactionDeleted(let reaction2, let message2, let user2, _)):
            return reaction1 == reaction2 && message1 == message2 && user1 == user2
        case (.typingStart(let user1, _), .typingStart(let user2, _)):
            return user1 == user2
        case (.typingStop(let user1, _), .typingStop(let user2, _)):
            return user1 == user2
        case (.notificationMarkRead(let channel1, let unreadCount1, let unreadChannels1, _),
              .notificationMarkRead(let channel2, let unreadCount2, let unreadChannels2, _)):
            return channel1 == channel2 && unreadCount1 == unreadCount2 && unreadChannels1 == unreadChannels2
        case (.notificationInvited(let channel1, _), .notificationInvited(let channel2, _)),
             (.notificationInviteAccepted(let channel1, _), .notificationInviteAccepted(let channel2, _)),
             (.notificationInviteRejected(let channel1, _), .notificationInviteRejected(let channel2, _)):
            return channel1 == channel2
        default:
            return false
        }
    }
}
