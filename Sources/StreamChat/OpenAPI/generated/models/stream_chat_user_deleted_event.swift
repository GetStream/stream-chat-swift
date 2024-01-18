//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserDeletedEvent: Codable, Hashable, Event {
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var createdAt: Date
    
    public var deleteConversationChannels: Bool
    
    public var hardDelete: Bool
    
    public var markMessagesDeleted: Bool
    
    public init(type: String, user: StreamChatUserObject?, createdAt: Date, deleteConversationChannels: Bool, hardDelete: Bool, markMessagesDeleted: Bool) {
        self.type = type
        
        self.user = user
        
        self.createdAt = createdAt
        
        self.deleteConversationChannels = deleteConversationChannels
        
        self.hardDelete = hardDelete
        
        self.markMessagesDeleted = markMessagesDeleted
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case user
        
        case createdAt = "created_at"
        
        case deleteConversationChannels = "delete_conversation_channels"
        
        case hardDelete = "hard_delete"
        
        case markMessagesDeleted = "mark_messages_deleted"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deleteConversationChannels, forKey: .deleteConversationChannels)
        
        try container.encode(hardDelete, forKey: .hardDelete)
        
        try container.encode(markMessagesDeleted, forKey: .markMessagesDeleted)
    }
}
