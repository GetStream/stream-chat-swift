//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallMemberUpdatedPermissionEvent: Codable, Hashable {
    public var capabilitiesByRole: [String: RawJSON]
    
    public var createdAt: Date
    
    public var members: [StreamChatMemberResponse]
    
    public var type: String
    
    public var call: StreamChatCallResponse
    
    public var callCid: String
    
    public init(capabilitiesByRole: [String: RawJSON], createdAt: Date, members: [StreamChatMemberResponse], type: String, call: StreamChatCallResponse, callCid: String) {
        self.capabilitiesByRole = capabilitiesByRole
        
        self.createdAt = createdAt
        
        self.members = members
        
        self.type = type
        
        self.call = call
        
        self.callCid = callCid
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case capabilitiesByRole = "capabilities_by_role"
        
        case createdAt = "created_at"
        
        case members
        
        case type
        
        case call
        
        case callCid = "call_cid"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(capabilitiesByRole, forKey: .capabilitiesByRole)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(call, forKey: .call)
        
        try container.encode(callCid, forKey: .callCid)
    }
}
