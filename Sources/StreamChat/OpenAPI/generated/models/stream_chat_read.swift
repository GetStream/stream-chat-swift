//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatRead: Codable, Hashable {
    public var lastReadMessageId: String?
    
    public var unreadMessages: Int
    
    public var user: StreamChatUserObject?
    
    public var lastRead: Date
    
    public init(lastReadMessageId: String?, unreadMessages: Int, user: StreamChatUserObject?, lastRead: Date) {
        self.lastReadMessageId = lastReadMessageId
        
        self.unreadMessages = unreadMessages
        
        self.user = user
        
        self.lastRead = lastRead
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case lastReadMessageId = "last_read_message_id"
        
        case unreadMessages = "unread_messages"
        
        case user
        
        case lastRead = "last_read"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(lastReadMessageId, forKey: .lastReadMessageId)
        
        try container.encode(unreadMessages, forKey: .unreadMessages)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(lastRead, forKey: .lastRead)
    }
}
