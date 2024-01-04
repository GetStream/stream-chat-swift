//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdatedCallPermissionsEvent: Codable, Hashable {
    public var user: StreamChatUserResponse
    
    public var callCid: String
    
    public var createdAt: String
    
    public var ownCapabilities: [StreamChatOwnCapability]
    
    public var type: String
    
    public init(user: StreamChatUserResponse, callCid: String, createdAt: String, ownCapabilities: [StreamChatOwnCapability], type: String) {
        self.user = user
        
        self.callCid = callCid
        
        self.createdAt = createdAt
        
        self.ownCapabilities = ownCapabilities
        
        self.type = type
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case callCid = "call_cid"
        
        case createdAt = "created_at"
        
        case ownCapabilities = "own_capabilities"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
        
        try container.encode(type, forKey: .type)
    }
}
