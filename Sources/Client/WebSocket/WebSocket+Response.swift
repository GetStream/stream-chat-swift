//
//  WebSocket+Response.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 23/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebSocket {
    enum Connection: Equatable {
        case notConnected
        case connecting
        case connected(_ connectionId: String, User)
        case disconnected(Error?)
        
        static func == (lhs: Connection, rhs: Connection) -> Bool {
            switch (lhs, rhs) {
            case (.notConnected, .notConnected),
                 (.connecting, .connecting),
                 (.disconnected, .disconnected):
                return true
            case let (.connected(connectionId1, user1), .connected(connectionId2, user2)):
                return connectionId1 == connectionId2 && user1 == user2
            default:
                return false
            }
        }
    }
}

extension WebSocket {
    struct Response: Decodable {
        private enum CodingKeys: String, CodingKey {
            case channelId = "cid"
            case created = "created_at"
        }
        
        private static let channelInfoSeparator: Character = ":"
        
        let channelId: String
        let channelType: ChannelType
        let event: Event
        let created: Date
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let channelInfo = try container.decode(String.self, forKey: .channelId)
            
            if channelInfo.contains(Response.channelInfoSeparator) {
                let channelPair = channelInfo.split(separator: Response.channelInfoSeparator)
                channelId = String(channelPair[1])
                channelType = ChannelType(rawValue: String(channelPair[0])) ?? .unknown
            } else {
                channelId = channelInfo
                channelType = .unknown
            }
            
            event = try Event(from: decoder)
            created = try container.decode(Date.self, forKey: .created)
        }
    }
}

extension WebSocket {
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
            case totalUnreadCount = "total_unread_count"
        }
        
        struct ResponseTypeError: Error {
            let type: String
        }
        
        case healthCheck(_ connectionId: String, User?)
        
        case messageRead(user: User)
        case messageNew(Message, User, _ watcherCount: Int, _ unreadCount: Int, _ totalUnreadCount: Int)
        
        case userUpdated(user: User)
        case userStatusChanged(user: User)
        case userStartWatching(user: User, watcherCount: Int)
        case userStopWatching(user: User, watcherCount: Int)
        
        case reactionNew(reaction: Reaction, to: Message, user: User)
        case reactionDeleted(reaction: Reaction, from: Message, user: User)
        
        case typingStart(user: User)
        case typingStop(user: User)
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            
            if type == "health.check" {
                let connectionId = try container.decode(String.self, forKey: .connectionId)
                let user = try container.decodeIfPresent(User.self, forKey: .me)
                self = .healthCheck(connectionId, user)
                return
            }
            
            let user = try container.decode(User.self, forKey: .user)
            
            switch type {
            // Message
            case "message.new":
                let message = try container.decode(Message.self, forKey: .message)
                let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
                let unreadCount = try container.decode(Int.self, forKey: .unreadCount)
                let totalUnreadCount = try container.decode(Int.self, forKey: .totalUnreadCount)
                self = .messageNew(message, user, watcherCount, unreadCount, totalUnreadCount)
            case "message.read":
                self = .messageRead(user: user)
                
            // User
            case "user.updated":
                self = .userUpdated(user: user)
            case "user.status.changed":
                self = .userStatusChanged(user: user)
            case "user.watching.start":
                let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
                self = .userStartWatching(user: user, watcherCount: watcherCount)
            case "user.watching.stop":
                let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
                self = .userStopWatching(user: user, watcherCount: watcherCount)
                
            // Reaction
            case "reaction.new":
                let reaction = try container.decode(Reaction.self, forKey: .reaction)
                let message = try container.decode(Message.self, forKey: .message)
                self = .reactionNew(reaction: reaction, to: message, user: user)
            case "reaction.deleted":
                let reaction = try container.decode(Reaction.self, forKey: .reaction)
                let message = try container.decode(Message.self, forKey: .message)
                self = .reactionDeleted(reaction: reaction, from: message, user: user)
                
            // Typing
            case "typing.start":
                self = .typingStart(user: user)
            case "typing.stop":
                self = .typingStop(user: user)
            default:
                throw ResponseTypeError(type: type)
            }
        }
    }
}
