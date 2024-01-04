//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallMemberUpdatedEvent: Codable, Hashable {
    public var call: StreamChatCallResponse
    
    public var callCid: String
    
    public var createdAt: String
    
    public var members: [StreamChatMemberResponse]
    
    public var type: String
    
    public init(call: StreamChatCallResponse, callCid: String, createdAt: String, members: [StreamChatMemberResponse], type: String) {
        self.call = call
        
        self.callCid = callCid
        
        self.createdAt = createdAt
        
        self.members = members
        
        self.type = type
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        
        case callCid = "call_cid"
        
        case createdAt = "created_at"
        
        case members
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(call, forKey: .call)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(type, forKey: .type)
    }
}
