//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPinRequest: Codable, Hashable {
    public var sessionId: String
    
    public var userId: String
    
    public init(sessionId: String, userId: String) {
        self.sessionId = sessionId
        
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case sessionId = "session_id"
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(sessionId, forKey: .sessionId)
        
        try container.encode(userId, forKey: .userId)
    }
}
