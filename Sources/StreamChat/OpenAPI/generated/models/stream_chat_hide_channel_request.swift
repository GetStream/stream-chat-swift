//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatHideChannelRequest: Codable, Hashable {
    public var userId: String?
    
    public var clearHistory: Bool?
    
    public var user: StreamChatUserObjectRequest?
    
    public init(userId: String?, clearHistory: Bool?, user: StreamChatUserObjectRequest?) {
        self.userId = userId
        
        self.clearHistory = clearHistory
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
        
        case clearHistory = "clear_history"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(clearHistory, forKey: .clearHistory)
        
        try container.encode(user, forKey: .user)
    }
}
