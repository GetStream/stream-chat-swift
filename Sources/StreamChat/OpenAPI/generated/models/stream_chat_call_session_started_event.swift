//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallSessionStartedEvent: Codable, Hashable {
    public var createdAt: String
    
    public var sessionId: String
    
    public var type: String
    
    public var call: StreamChatCallResponse
    
    public var callCid: String
    
    public init(createdAt: String, sessionId: String, type: String, call: StreamChatCallResponse, callCid: String) {
        self.createdAt = createdAt
        
        self.sessionId = sessionId
        
        self.type = type
        
        self.call = call
        
        self.callCid = callCid
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case sessionId = "session_id"
        
        case type
        
        case call
        
        case callCid = "call_cid"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(sessionId, forKey: .sessionId)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(call, forKey: .call)
        
        try container.encode(callCid, forKey: .callCid)
    }
}
