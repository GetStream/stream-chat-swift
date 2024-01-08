//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateChannelPartialRequest: Codable, Hashable {
    public var userId: String?
    
    public var set: [String: RawJSON]
    
    public var unset: [String]
    
    public var user: StreamChatUserObjectRequest?
    
    public init(userId: String?, set: [String: RawJSON], unset: [String], user: StreamChatUserObjectRequest?) {
        self.userId = userId
        
        self.set = set
        
        self.unset = unset
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
        
        case set
        
        case unset
        
        case user
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(set, forKey: .set)
        
        try container.encode(unset, forKey: .unset)
        
        try container.encode(user, forKey: .user)
    }
}
