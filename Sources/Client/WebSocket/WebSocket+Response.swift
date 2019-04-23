//
//  WebSocket+Response.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 23/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebSocket {
    struct Response: Decodable {
        private enum CodingKeys: String, CodingKey {
            case type
            case channelId = "cid"
            case created = "created_at"
        }
        
        let channelId: String
        let type: ResponseType
        let created: Date
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            channelId = try container.decode(String.self, forKey: .channelId)
            type = try ResponseType(from: decoder)
            created = try container.decode(Date.self, forKey: .created)
        }
    }
}

extension WebSocket {
    enum ResponseType: Decodable {
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
        
        case empty
        case healthCheck(connectionId: String, user: User?)
        case messageRead(user: User)
        case messageNew(message: Message, user: User, watcherCount: Int, unreadCount: Int, totalUnreadCount: Int)
        case userStartWatching(user: User, watcherCount: Int)
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
                self = .healthCheck(connectionId: connectionId, user: user)
                return
            }
            
            let user = try container.decode(User.self, forKey: .user)
            
            switch type {
            case "message.new":
                let message = try container.decode(Message.self, forKey: .message)
                let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
                let unreadCount = try container.decode(Int.self, forKey: .unreadCount)
                let totalUnreadCount = try container.decode(Int.self, forKey: .totalUnreadCount)
                
                self = .messageNew(message: message,
                                   user: user,
                                   watcherCount: watcherCount,
                                   unreadCount: unreadCount,
                                   totalUnreadCount: totalUnreadCount)
            case "message.read":
                self = .messageRead(user: user)
            case "user.watching.start":
                let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
                self = .userStartWatching(user: user, watcherCount: watcherCount)
            case "reaction.new":
                let reaction = try container.decode(Reaction.self, forKey: .reaction)
                let message = try container.decode(Message.self, forKey: .message)
                self = .reactionNew(reaction: reaction, to: message, user: user)
            case "reaction.deleted":
                let reaction = try container.decode(Reaction.self, forKey: .reaction)
                let message = try container.decode(Message.self, forKey: .message)
                self = .reactionDeleted(reaction: reaction, from: message, user: user)
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
