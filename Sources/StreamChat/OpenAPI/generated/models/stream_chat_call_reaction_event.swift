//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallReactionEvent: Codable, Hashable {
    public var callCid: String
    
    public var createdAt: Date
    
    public var reaction: StreamChatReactionResponse
    
    public var type: String
    
    public init(callCid: String, createdAt: Date, reaction: StreamChatReactionResponse, type: String) {
        self.callCid = callCid
        
        self.createdAt = createdAt
        
        self.reaction = reaction
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        
        case createdAt = "created_at"
        
        case reaction
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(type, forKey: .type)
    }
}
