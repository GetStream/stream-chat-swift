//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTruncateChannelRequest: Codable, Hashable {
    public var hardDelete: Bool?
    
    public var message: StreamChatMessageRequest?
    
    public var skipPush: Bool?
    
    public var truncatedAt: String?
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public init(hardDelete: Bool?, message: StreamChatMessageRequest?, skipPush: Bool?, truncatedAt: String?, user: StreamChatUserObjectRequest?, userId: String?) {
        self.hardDelete = hardDelete
        
        self.message = message
        
        self.skipPush = skipPush
        
        self.truncatedAt = truncatedAt
        
        self.user = user
        
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hardDelete = "hard_delete"
        
        case message
        
        case skipPush = "skip_push"
        
        case truncatedAt = "truncated_at"
        
        case user
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(hardDelete, forKey: .hardDelete)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(skipPush, forKey: .skipPush)
        
        try container.encode(truncatedAt, forKey: .truncatedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
    }
}
