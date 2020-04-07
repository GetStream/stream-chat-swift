//
//  Event.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

/// A web socket event.
public enum ClientEvent: Event {
    private enum CodingKeys: String, CodingKey {
        case connectionId = "connection_id"
        case type
        case me
        case user
        case cid
        case channel
        case message
        case channelsUnreadCount = "unread_channels"
        case messagesUnreadCount = "total_unread_count"
        case watcherCount = "watcher_count"
        case created = "created_at"
    }
    
    /// When the connection state changed.
    case connectionChanged(ConnectionState)
    /// Every 30 second to confirm that the client connection is still active.
    case healthCheck(User, _ connectionId: String)
    /// A pong event.
    case pong
    
    /// When a user presence changed, e.g. online, offline, away (when subscribed to the user presence).
    case userPresenceChanged(User, ClientEventType)
    /// When a user was updated (when subscribed to the user presence).
    case userUpdated(User, ClientEventType)
    
    /// When a new message was added on a channel (when clients that are not currently watching the channel).
    case notificationMessageNew(Message, Channel, UnreadCount, _ watcherCount: Int, ClientEventType)
    /// When the count of unread messages changed for the channel where the user is a member.
    case notificationMarkRead(MessageRead, Channel, UnreadCount, ClientEventType)
    /// When the total count of unread messages (across all channels the user is a member) changed
    /// (when clients from the user affected by the change).
    case notificationMarkAllRead(MessageRead, ClientEventType)
    /// When the user mutes someone.
    case notificationMutesUpdated(User, ChannelId, ClientEventType)
    
    /// When the user accepts an invite (when the user invited).
    case notificationAddedToChannel(Channel, UnreadCount, ClientEventType)
    /// When a user was removed from a channel (when the user invited).
    case notificationRemovedFromChannel(Channel, ClientEventType)
    
    /// When the user was invited to join a channel (when the user invited).
    case notificationInvited(Channel, ClientEventType)
    /// When the user accepts an invite (when the user invited).
    case notificationInviteAccepted(Channel, ClientEventType)
    /// When the user reject an invite (when the user invited).
    case notificationInviteRejected(Channel, ClientEventType)
    
    /// An event type.
    public var type: ClientEventType {
        switch self {
        case .connectionChanged:
            return .connectionChanged
        case .healthCheck:
            return .healthCheck
        case .pong:
            return .pong
        case .userPresenceChanged:
            return .userPresenceChanged
        case .userUpdated:
            return .userUpdated
            
        case .notificationMessageNew(_, _, _, _, let type),
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
    
    /// A user from the event.
    public var user: User? {
        switch self {
        case .healthCheck(let user, _),
             .userPresenceChanged(let user, _),
             .userUpdated(let user, _),
             .notificationMutesUpdated(let user, _, _):
            return user
        case .notificationMessageNew(let message, _, _, _, _):
            return message.user
        default:
            return nil
        }
    }
    
    // MARK: Decoder
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ClientEventType.self, forKey: .type)
        
        func user() throws -> User {
            try container.decode(User.self, forKey: .user)
        }
        
        func cid() throws -> ChannelId {
            try container.decode(ChannelId.self, forKey: .cid)
        }
        
        func channel() throws -> Channel {
            try container.decode(Channel.self, forKey: .channel)
        }
        
        func created() throws -> Date {
            try container.decode(Date.self, forKey: .created)
        }
        
        func unreadCount() throws -> UnreadCount {
            let channelsUnreadCount = try container.decodeIfPresent(Int.self, forKey: .channelsUnreadCount) ?? 0
            let messagesUnreadCount = try container.decodeIfPresent(Int.self, forKey: .messagesUnreadCount) ?? 0
            return UnreadCount(channels: channelsUnreadCount, messages: messagesUnreadCount)
        }
        
        switch type {
        // Connection
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
            
        // User
        case .userUpdated:
            self = try .userUpdated(user(), type)
        case .userPresenceChanged:
            self = try .userPresenceChanged(user(), type)
            
        // Notifications
        case .notificationMutesUpdated:
            self = try .notificationMutesUpdated(container.decode(User.self, forKey: .me), cid(), type)
        case .notificationMarkRead:
            let messageRead = try MessageRead(user: .current, lastReadDate: created())
            
            if let channel = try container.decodeIfPresent(Channel.self, forKey: .channel) {
                self = try .notificationMarkRead(messageRead, channel, unreadCount(), type)
            } else {
                self = .notificationMarkAllRead(messageRead, type)
            }
        case .notificationAddedToChannel:
            self = try .notificationAddedToChannel(channel(), unreadCount(), type)
        case .notificationRemovedFromChannel:
            self = try .notificationRemovedFromChannel(channel(), type)
        case .notificationMessageNew:
            let message = try container.decode(Message.self, forKey: .message)
            let watcherCount = try container.decodeIfPresent(Int.self, forKey: .watcherCount) ?? 0
            self = try .notificationMessageNew(message, channel(), unreadCount(), watcherCount, type)
            
        // Invites
        case .notificationInvited:
            self = try .notificationInvited(channel(), type)
        case .notificationInviteAccepted:
            self = try .notificationInviteAccepted(channel(), type)
        case .notificationInviteRejected:
            self = try .notificationInviteRejected(channel(), type)
        }
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: ClientEvent, rhs: ClientEvent) -> Bool {
        switch (lhs, rhs) {
        case (let .connectionChanged(state1), let .connectionChanged(state2)):
            return state1 == state2
        case (.healthCheck, .healthCheck), (.pong, .pong): return true
        case (let .userUpdated(user1, _), let .userUpdated(user2, _)): return user1 == user2
        case (let .userPresenceChanged(user1, _), let .userPresenceChanged(user2, _)): return user1 == user2
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
        default: return false
        }
    }
}
