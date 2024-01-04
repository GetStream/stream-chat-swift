//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallUserMuted: Codable, Hashable {
    public var mutedUserIds: [String]
    
    public var type: String
    
    public var callCid: String
    
    public var createdAt: String
    
    public var fromUserId: String
    
    public init(mutedUserIds: [String], type: String, callCid: String, createdAt: String, fromUserId: String) {
        self.mutedUserIds = mutedUserIds
        
        self.type = type
        
        self.callCid = callCid
        
        self.createdAt = createdAt
        
        self.fromUserId = fromUserId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case mutedUserIds = "muted_user_ids"
        
        case type
        
        case callCid = "call_cid"
        
        case createdAt = "created_at"
        
        case fromUserId = "from_user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(mutedUserIds, forKey: .mutedUserIds)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(fromUserId, forKey: .fromUserId)
    }
}
