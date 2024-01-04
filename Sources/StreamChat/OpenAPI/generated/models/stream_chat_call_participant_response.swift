//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallParticipantResponse: Codable, Hashable {
    public var joinedAt: String
    
    public var role: String
    
    public var user: StreamChatUserResponse
    
    public var userSessionId: String
    
    public init(joinedAt: String, role: String, user: StreamChatUserResponse, userSessionId: String) {
        self.joinedAt = joinedAt
        
        self.role = role
        
        self.user = user
        
        self.userSessionId = userSessionId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case joinedAt = "joined_at"
        
        case role
        
        case user
        
        case userSessionId = "user_session_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(joinedAt, forKey: .joinedAt)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userSessionId, forKey: .userSessionId)
    }
}
