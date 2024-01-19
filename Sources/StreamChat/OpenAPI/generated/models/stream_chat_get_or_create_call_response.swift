//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGetOrCreateCallResponse: Codable, Hashable {
    public var call: StreamChatCallResponse
    
    public var created: Bool
    
    public var duration: String
    
    public var members: [StreamChatMemberResponse]
    
    public var membership: StreamChatMemberResponse?
    
    public var ownCapabilities: [StreamChatOwnCapability]
    
    public init(call: StreamChatCallResponse, created: Bool, duration: String, members: [StreamChatMemberResponse], membership: StreamChatMemberResponse?, ownCapabilities: [StreamChatOwnCapability]) {
        self.call = call
        
        self.created = created
        
        self.duration = duration
        
        self.members = members
        
        self.membership = membership
        
        self.ownCapabilities = ownCapabilities
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        
        case created
        
        case duration
        
        case members
        
        case membership
        
        case ownCapabilities = "own_capabilities"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(call, forKey: .call)
        
        try container.encode(created, forKey: .created)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(membership, forKey: .membership)
        
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
    }
}
