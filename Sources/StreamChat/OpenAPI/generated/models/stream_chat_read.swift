//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatRead: Codable, Hashable {
    public var lastRead: Date
    
    public var lastReadMessageId: String?
    
    public var unreadMessages: Int
    
    public var user: StreamChatUserObject?
    
    public init(lastRead: Date, lastReadMessageId: String?, unreadMessages: Int, user: StreamChatUserObject?) {
        self.lastRead = lastRead
        
        self.lastReadMessageId = lastReadMessageId
        
        self.unreadMessages = unreadMessages
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case lastRead = "last_read"
        
        case lastReadMessageId = "last_read_message_id"
        
        case unreadMessages = "unread_messages"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(lastRead, forKey: .lastRead)
        
        try container.encode(lastReadMessageId, forKey: .lastReadMessageId)
        
        try container.encode(unreadMessages, forKey: .unreadMessages)
        
        try container.encode(user, forKey: .user)
    }
}
