//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatRead: Codable, Hashable {
    public var unreadMessages: Int
    
    public var user: StreamChatUserObject?
    
    public var lastRead: String
    
    public var lastReadMessageId: String?
    
    public init(unreadMessages: Int, user: StreamChatUserObject?, lastRead: String, lastReadMessageId: String?) {
        self.unreadMessages = unreadMessages
        
        self.user = user
        
        self.lastRead = lastRead
        
        self.lastReadMessageId = lastReadMessageId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case unreadMessages = "unread_messages"
        
        case user
        
        case lastRead = "last_read"
        
        case lastReadMessageId = "last_read_message_id"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(unreadMessages, forKey: .unreadMessages)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(lastRead, forKey: .lastRead)
        
        try container.encode(lastReadMessageId, forKey: .lastReadMessageId)
    }
}
