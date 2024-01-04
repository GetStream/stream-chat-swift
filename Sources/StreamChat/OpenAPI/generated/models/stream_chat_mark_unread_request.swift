//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMarkUnreadRequest: Codable, Hashable {
    public var messageId: String
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public init(messageId: String, user: StreamChatUserObjectRequest?, userId: String?) {
        self.messageId = messageId
        
        self.user = user
        
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case messageId = "message_id"
        
        case user
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
    }
}
