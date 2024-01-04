//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallRingEvent: Codable, Hashable {
    public var call: StreamChatCallResponse
    
    public var callCid: String
    
    public var createdAt: String
    
    public var members: [StreamChatMemberResponse]
    
    public var sessionId: String
    
    public var type: String
    
    public var user: StreamChatUserResponse
    
    public init(call: StreamChatCallResponse, callCid: String, createdAt: String, members: [StreamChatMemberResponse], sessionId: String, type: String, user: StreamChatUserResponse) {
        self.call = call
        
        self.callCid = callCid
        
        self.createdAt = createdAt
        
        self.members = members
        
        self.sessionId = sessionId
        
        self.type = type
        
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        
        case callCid = "call_cid"
        
        case createdAt = "created_at"
        
        case members
        
        case sessionId = "session_id"
        
        case type
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(call, forKey: .call)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(sessionId, forKey: .sessionId)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}
