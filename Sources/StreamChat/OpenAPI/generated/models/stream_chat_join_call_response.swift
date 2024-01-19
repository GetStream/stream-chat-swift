//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatJoinCallResponse: Codable, Hashable {
    public var membership: StreamChatMemberResponse?
    
    public var ownCapabilities: [StreamChatOwnCapability]
    
    public var call: StreamChatCallResponse
    
    public var created: Bool
    
    public var credentials: StreamChatCredentials
    
    public var duration: String
    
    public var members: [StreamChatMemberResponse]
    
    public init(membership: StreamChatMemberResponse?, ownCapabilities: [StreamChatOwnCapability], call: StreamChatCallResponse, created: Bool, credentials: StreamChatCredentials, duration: String, members: [StreamChatMemberResponse]) {
        self.membership = membership
        
        self.ownCapabilities = ownCapabilities
        
        self.call = call
        
        self.created = created
        
        self.credentials = credentials
        
        self.duration = duration
        
        self.members = members
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case membership
        
        case ownCapabilities = "own_capabilities"
        
        case call
        
        case created
        
        case credentials
        
        case duration
        
        case members
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(membership, forKey: .membership)
        
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
        
        try container.encode(call, forKey: .call)
        
        try container.encode(created, forKey: .created)
        
        try container.encode(credentials, forKey: .credentials)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(members, forKey: .members)
    }
}
