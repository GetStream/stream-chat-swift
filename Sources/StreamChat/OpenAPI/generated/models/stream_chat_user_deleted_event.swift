//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserDeletedEvent: Codable, Hashable {
    public var hardDelete: Bool
    
    public var markMessagesDeleted: Bool
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var createdAt: String
    
    public var deleteConversationChannels: Bool
    
    public init(hardDelete: Bool, markMessagesDeleted: Bool, type: String, user: StreamChatUserObject?, createdAt: String, deleteConversationChannels: Bool) {
        self.hardDelete = hardDelete
        
        self.markMessagesDeleted = markMessagesDeleted
        
        self.type = type
        
        self.user = user
        
        self.createdAt = createdAt
        
        self.deleteConversationChannels = deleteConversationChannels
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hardDelete = "hard_delete"
        
        case markMessagesDeleted = "mark_messages_deleted"
        
        case type
        
        case user
        
        case createdAt = "created_at"
        
        case deleteConversationChannels = "delete_conversation_channels"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(hardDelete, forKey: .hardDelete)
        
        try container.encode(markMessagesDeleted, forKey: .markMessagesDeleted)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deleteConversationChannels, forKey: .deleteConversationChannels)
    }
}
