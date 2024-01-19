//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallUserMuted: Codable, Hashable {
    public var callCid: String
    
    public var createdAt: Date
    
    public var fromUserId: String
    
    public var mutedUserIds: [String]
    
    public var type: String
    
    public init(callCid: String, createdAt: Date, fromUserId: String, mutedUserIds: [String], type: String) {
        self.callCid = callCid
        
        self.createdAt = createdAt
        
        self.fromUserId = fromUserId
        
        self.mutedUserIds = mutedUserIds
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        
        case createdAt = "created_at"
        
        case fromUserId = "from_user_id"
        
        case mutedUserIds = "muted_user_ids"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(fromUserId, forKey: .fromUserId)
        
        try container.encode(mutedUserIds, forKey: .mutedUserIds)
        
        try container.encode(type, forKey: .type)
    }
}
