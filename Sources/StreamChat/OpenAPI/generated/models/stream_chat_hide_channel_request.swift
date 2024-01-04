//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatHideChannelRequest: Codable, Hashable {
    public var clearHistory: Bool?
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public init(clearHistory: Bool?, user: StreamChatUserObjectRequest?, userId: String?) {
        self.clearHistory = clearHistory
        
        self.user = user
        
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case clearHistory = "clear_history"
        
        case user
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(clearHistory, forKey: .clearHistory)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
    }
}
