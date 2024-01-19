//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCreateCallRequest: Codable, Hashable {
    public var id: String
    
    public var options: [String: RawJSON]?
    
    public var type: String
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public init(id: String, options: [String: RawJSON]?, type: String, user: StreamChatUserObjectRequest?, userId: String?) {
        self.id = id
        
        self.options = options
        
        self.type = type
        
        self.user = user
        
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        
        case options
        
        case type
        
        case user
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(options, forKey: .options)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
    }
}
