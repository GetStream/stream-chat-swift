//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMarkChannelsReadRequest: Codable, Hashable {
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public init(user: StreamChatUserObjectRequest?, userId: String?) {
        self.user = user
        
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
    }
}
