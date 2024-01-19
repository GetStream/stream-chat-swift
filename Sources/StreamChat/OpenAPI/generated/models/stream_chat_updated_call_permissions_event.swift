//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdatedCallPermissionsEvent: Codable, Hashable {
    public var callCid: String
    
    public var createdAt: Date
    
    public var ownCapabilities: [StreamChatOwnCapability]
    
    public var type: String
    
    public var user: StreamChatUserResponse
    
    public init(callCid: String, createdAt: Date, ownCapabilities: [StreamChatOwnCapability], type: String, user: StreamChatUserResponse) {
        self.callCid = callCid
        
        self.createdAt = createdAt
        
        self.ownCapabilities = ownCapabilities
        
        self.type = type
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        
        case createdAt = "created_at"
        
        case ownCapabilities = "own_capabilities"
        
        case type
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}
