//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallAcceptedEvent: Codable, Hashable {
    public var createdAt: String
    
    public var type: String
    
    public var user: StreamChatUserResponse
    
    public var call: StreamChatCallResponse
    
    public var callCid: String
    
    public init(createdAt: String, type: String, user: StreamChatUserResponse, call: StreamChatCallResponse, callCid: String) {
        self.createdAt = createdAt
        
        self.type = type
        
        self.user = user
        
        self.call = call
        
        self.callCid = callCid
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case type
        
        case user
        
        case call
        
        case callCid = "call_cid"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(call, forKey: .call)
        
        try container.encode(callCid, forKey: .callCid)
    }
}
