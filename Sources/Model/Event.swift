//
//  Event.swift
//  StreamChat
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
        case channel
        case message
        case reaction
        case unreadCount = "unread_count"
        case unreadChannels = "unread_channels"
        case totalUnreadCount = "total_unread_count"
        case created = "created_at"
    }
    
    struct ResponseTypeError: Swift.Error {
        let type: EventType
    }
    
    case healthCheck(_ connectionId: String, User?)
    
    case messageRead(MessageRead)
    case messageNew(Message, _ unreadCount: Int, _ totalUnreadCount: Int, Channel?)
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
        
        func user() throws -> User {
            return try container.decode(User.self, forKey: .user)
        }
        
        func message() throws -> Message {
            return try container.decode(Message.self, forKey: .message)
        }
        
        switch type {
        // Message
        case .messageNew, .notificationMessageNew:
            let channel = try container.decodeIfPresent(Channel.self, forKey: .channel)
            let newMessage = try message()
            let unreadCount = try container.decode(Int.self, forKey: .unreadCount)
            let totalUnreadCount = try container.decode(Int.self, forKey: .totalUnreadCount)
            self = .messageNew(newMessage, unreadCount, totalUnreadCount, channel)
        case .messageRead:
            let created = try container.decode(Date.self, forKey: .created)
            self = .messageRead(MessageRead(user: try user(), lastReadDate: created))
        case .messageDeleted:
            self = .messageDeleted(try message())
        case .messageUpdated:
            self = .messageUpdated(try message())
            
        // User
        case .userUpdated:
            self = .userUpdated(try user())
        case .userStatusChanged:
            self = .userStatusChanged(try user())
        case .userStartWatching:
            let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
            self = .userStartWatching(try user(), watcherCount)
        case .userStopWatching:
            let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
            self = .userStopWatching(try user(), watcherCount)
            
        // Typing
        case .typingStart:
            self = .typingStart(try user())
        case .typingStop:
            self = .typingStop(try user())
            
        // Reaction
        case .reactionNew:
            let reaction = try container.decode(Reaction.self, forKey: .reaction)
            self = .reactionNew(reaction, try message(), try user())
        case .reactionDeleted:
            let reaction = try container.decode(Reaction.self, forKey: .reaction)
            self = .reactionDeleted(reaction, try message(), try user())
            
        // Notifications
        case .notificationMarkRead:
            let unreadCount = try container.decode(Int.self, forKey: .unreadCount)
            let unreadChannels = try container.decode(Int.self, forKey: .unreadChannels)
            let totalUnreadCount = try container.decode(Int.self, forKey: .totalUnreadCount)
            self = .notificationMarkRead(unreadCount, totalUnreadCount, unreadChannels)
            
        default:
            throw ResponseTypeError(type: type)
        }
    }
}

extension Event: Equatable {
    static func == (lhs: Event, rhs: Event) -> Bool {
        switch (lhs, rhs) {
        case (.healthCheck, .healthCheck):
            return true
        case (.messageRead(let messageRead1), .messageRead(let messageRead2)):
            return messageRead1 == messageRead2
        case (.messageNew(let message1, let unreadCount1, let totalUnreadCount1, let channel1),
              .messageNew(let message2, let unreadCount2, let totalUnreadCount2, let channel2)):
            return message1 == message2
                && unreadCount1 == unreadCount2
                && totalUnreadCount1 == totalUnreadCount2
                && channel1 == channel2
        case (.messageDeleted(let message1), .messageDeleted(let message2)):
            return message1 == message2
        case (.messageUpdated(let message1), .messageUpdated(let message2)):
            return message1 == message2
        case (.userUpdated(let user1), .userUpdated(let user2)):
            return user1 == user2
        case (.userStatusChanged(let user1), .userStatusChanged(let user2)):
            return user1 == user2
        case (.userStartWatching(let user1, let watcherCount1), .userStartWatching(let user2, let watcherCount2)):
            return user1 == user2 && watcherCount1 == watcherCount2
        case (.userStopWatching(let user1, let watcherCount1), .userStopWatching(let user2, let watcherCount2)):
            return user1 == user2 && watcherCount1 == watcherCount2
        case (.reactionNew(let reaction1, let message1, let user1), .reactionNew(let reaction2, let message2, let user2)):
            return reaction1 == reaction2 && message1 == message2 && user1 == user2
        case (.reactionDeleted(let reaction1, let message1, let user1), .reactionDeleted(let reaction2, let message2, let user2)):
            return reaction1 == reaction2 && message1 == message2 && user1 == user2
        case (.typingStart(let user1), .typingStart(let user2)):
            return user1 == user2
        case (.typingStop(let user1), .typingStop(let user2)):
            return user1 == user2
        case (.notificationMarkRead(let unreadCount1, let totalUnreadCount1, let unreadChannels1),
              .notificationMarkRead(let unreadCount2, let totalUnreadCount2, let unreadChannels2)):
            return unreadCount1 == unreadCount2 && totalUnreadCount1 == totalUnreadCount2 && unreadChannels1 == unreadChannels2
        default:
            return false
        }
    }
}
