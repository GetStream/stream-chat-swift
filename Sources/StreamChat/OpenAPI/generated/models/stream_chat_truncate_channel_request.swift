//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTruncateChannelRequest: Codable, Hashable {
    public var message: StreamChatMessageRequest?
    
    public var skipPush: Bool?
    
    public var truncatedAt: String?
    
    public var hardDelete: Bool?
    
    public init(message: StreamChatMessageRequest?, skipPush: Bool?, truncatedAt: String?, hardDelete: Bool?) {
        self.message = message
        
        self.skipPush = skipPush
        
        self.truncatedAt = truncatedAt
        
        self.hardDelete = hardDelete
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        
        case skipPush = "skip_push"
        
        case truncatedAt = "truncated_at"
        
        case hardDelete = "hard_delete"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(skipPush, forKey: .skipPush)
        
        try container.encode(truncatedAt, forKey: .truncatedAt)
        
        try container.encode(hardDelete, forKey: .hardDelete)
    }
}
