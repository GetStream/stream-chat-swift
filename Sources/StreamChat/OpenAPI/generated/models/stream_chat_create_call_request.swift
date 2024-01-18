//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCreateCallRequest: Codable, Hashable {
    public var userId: String?
    
    public var id: String
    
    public var options: [String: RawJSON]?
    
    public var type: String
    
    public var user: StreamChatUserObjectRequest?
    
    public init(userId: String?, id: String, options: [String: RawJSON]?, type: String, user: StreamChatUserObjectRequest?) {
        self.userId = userId
        
        self.id = id
        
        self.options = options
        
        self.type = type
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
        
        case id
        
        case options
        
        case type
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(options, forKey: .options)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}
