//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTruncateChannelRequest: Codable, Hashable {
    public var skipPush: Bool?
    
    public var truncatedAt: Date?
    
    public var hardDelete: Bool?
    
    public var message: StreamChatMessageRequest?
    
    public init(skipPush: Bool?, truncatedAt: Date?, hardDelete: Bool?, message: StreamChatMessageRequest?) {
        self.skipPush = skipPush
        
        self.truncatedAt = truncatedAt
        
        self.hardDelete = hardDelete
        
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case skipPush = "skip_push"
        
        case truncatedAt = "truncated_at"
        
        case hardDelete = "hard_delete"
        
        case message
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(skipPush, forKey: .skipPush)
        
        try container.encode(truncatedAt, forKey: .truncatedAt)
        
        try container.encode(hardDelete, forKey: .hardDelete)
        
        try container.encode(message, forKey: .message)
    }
}
