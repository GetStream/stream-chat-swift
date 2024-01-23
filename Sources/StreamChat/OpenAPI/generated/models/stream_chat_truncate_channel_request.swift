//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTruncateChannelRequest: Codable, Hashable {
    public var hardDelete: Bool? = nil
    
    public var skipPush: Bool? = nil
    
    public var truncatedAt: Date? = nil
    
    public var message: StreamChatMessageRequest? = nil
    
    public init(hardDelete: Bool? = nil, skipPush: Bool? = nil, truncatedAt: Date? = nil, message: StreamChatMessageRequest? = nil) {
        self.hardDelete = hardDelete
        
        self.skipPush = skipPush
        
        self.truncatedAt = truncatedAt
        
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hardDelete = "hard_delete"
        
        case skipPush = "skip_push"
        
        case truncatedAt = "truncated_at"
        
        case message
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(hardDelete, forKey: .hardDelete)
        
        try container.encode(skipPush, forKey: .skipPush)
        
        try container.encode(truncatedAt, forKey: .truncatedAt)
        
        try container.encode(message, forKey: .message)
    }
}
