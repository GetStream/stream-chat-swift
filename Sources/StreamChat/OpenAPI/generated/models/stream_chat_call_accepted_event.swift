//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallAcceptedEvent: Codable, Hashable {
    public var call: StreamChatCallResponse
    
    public var callCid: String
    
    public var createdAt: Date
    
    public var type: String
    
    public var user: StreamChatUserResponse
    
    public init(call: StreamChatCallResponse, callCid: String, createdAt: Date, type: String, user: StreamChatUserResponse) {
        self.call = call
        
        self.callCid = callCid
        
        self.createdAt = createdAt
        
        self.type = type
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        
        case callCid = "call_cid"
        
        case createdAt = "created_at"
        
        case type
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(call, forKey: .call)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}
