//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateChannelPartialRequest: Codable, Hashable {
    public var unset: [String]
    
    public var set: [String: RawJSON]
    
    public var userId: String? = nil
    
    public var user: StreamChatUserObjectRequest? = nil
    
    public init(unset: [String], set: [String: RawJSON], userId: String? = nil, user: StreamChatUserObjectRequest? = nil) {
        self.unset = unset
        
        self.set = set
        
        self.userId = userId
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case unset
        
        case set
        
        case userId = "user_id"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(unset, forKey: .unset)
        
        try container.encode(set, forKey: .set)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(user, forKey: .user)
    }
}
