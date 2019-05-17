//
//  Event.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public enum EventType: String, Codable {
    case healthCheck = "health.check"
    case messageNew = "message.new"
    case messageRead = "message.read"
    case messageUpdated = "message.updated"
    case messageDeleted = "message.deleted"
    case messageReaction = "message.reaction"
    case userUpdated = "user.updated"
    case userStatusChanged = "user.status.changed"
    case userStartWatching = "user.watching.start"
    case userStopWatching = "user.watching.stop"
    case typingStart = "typing.start"
    case typingStop = "typing.stop"
    case reactionNew = "reaction.new"
    case reactionDeleted = "reaction.deleted"
    case notificationMarkRead = "notification.mark_read"
    case notificationMessageNew = "notification.message_new"
    case notificationInvited = "notification.invited"
    case notificationInviteAccepted = "notification.invite_accepted"
    case notificationAddedToChannel = "notification.added_to_channel"
    case notificationRemovedFromChannel = "notification.removed_from_channel"
    case memberAdded = "member.added"
    case memberUpdated = "member.updated"
    case memberRemoved = "member.removed"
    case channelUpdated = "channel.updated"
    case connectionChanged = "connection.changed"
    case connectionRecovered = "connection.recovered"
}

enum Event: Decodable {
    private enum CodingKeys: String, CodingKey {
        case connectionId = "connection_id"
        case type
        case me
        case user
        case watcherCount = "watcher_count"
        case message
        case reaction
        case unreadCount = "unread_count"
        case unreadChannels = "unread_channels"
        case totalUnreadCount = "total_unread_count"
    }
    
    struct ResponseTypeError: Swift.Error {
        let type: EventType
    }
    
    case healthCheck(_ connectionId: String, User?)
    
    case messageRead(user: User)
    case messageNew(Message, User, _ unreadCount: Int, _ totalUnreadCount: Int)
    case messageDeleted(Message)
    case messageUpdated(Message)
    
    case userUpdated(User)
    case userStatusChanged(User)
    case userStartWatching(User, _ watcherCount: Int)
    case userStopWatching(User, _ watcherCount: Int)
    
    case reactionNew(Reaction, Message, User)
    case reactionDeleted(Reaction, Message, User)
    
    case typingStart(User)
    case typingStop(User)
    
    case notificationMarkRead(_ unreadCount: Int, _ totalUnreadCount: Int, _ unreadChannels: Int)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EventType.self, forKey: .type)
        
        if type == .healthCheck {
            let connectionId = try container.decode(String.self, forKey: .connectionId)
            let user = try container.decodeIfPresent(User.self, forKey: .me)
            self = .healthCheck(connectionId, user)
            return
        }
        
        if type == .notificationMarkRead {
            let unreadCount = try container.decode(Int.self, forKey: .unreadCount)
            let unreadChannels = try container.decode(Int.self, forKey: .unreadChannels)
            let totalUnreadCount = try container.decode(Int.self, forKey: .totalUnreadCount)
            self = .notificationMarkRead(unreadCount, totalUnreadCount, unreadChannels)
            return
        }
        
        let user = try container.decode(User.self, forKey: .user)
        
        switch type {
        // Message
        case .messageNew:
            let message = try container.decode(Message.self, forKey: .message)
            let unreadCount = try container.decode(Int.self, forKey: .unreadCount)
            let totalUnreadCount = try container.decode(Int.self, forKey: .totalUnreadCount)
            self = .messageNew(message, user, unreadCount, totalUnreadCount)
        case .messageRead:
            self = .messageRead(user: user)
        case .messageDeleted:
            let message = try container.decode(Message.self, forKey: .message)
            self = .messageDeleted(message)
        case .messageUpdated:
            let message = try container.decode(Message.self, forKey: .message)
            self = .messageUpdated(message)
            
        // User
        case .userUpdated:
            self = .userUpdated(user)
        case .userStatusChanged:
            self = .userStatusChanged(user)
        case .userStartWatching:
            let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
            self = .userStartWatching(user, watcherCount)
        case .userStopWatching:
            let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
            self = .userStopWatching(user, watcherCount)
            
        // Typing
        case .typingStart:
            self = .typingStart(user)
        case .typingStop:
            self = .typingStop(user)
            
        // Reaction
        case .reactionNew:
            let reaction = try container.decode(Reaction.self, forKey: .reaction)
            let message = try container.decode(Message.self, forKey: .message)
            self = .reactionNew(reaction, message, user)
        case .reactionDeleted:
            let reaction = try container.decode(Reaction.self, forKey: .reaction)
            let message = try container.decode(Message.self, forKey: .message)
            self = .reactionDeleted(reaction, message, user)
            
        default:
            throw ResponseTypeError(type: type)
        }
    }
}
