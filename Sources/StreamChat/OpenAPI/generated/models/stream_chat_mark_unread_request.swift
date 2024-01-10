//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMarkUnreadRequest: Codable, Hashable {
    public var userId: String?
    
    public var messageId: String
    
    public var user: StreamChatUserObjectRequest?
    
    public init(userId: String?, messageId: String, user: StreamChatUserObjectRequest?) {
        self.userId = userId
        
        self.messageId = messageId
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
        
        case messageId = "message_id"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(user, forKey: .user)
    }
}
