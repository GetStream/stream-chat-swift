//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallReactionEvent: Codable, Hashable {
    public var createdAt: String
    
    public var reaction: StreamChatReactionResponse
    
    public var type: String
    
    public var callCid: String
    
    public init(createdAt: String, reaction: StreamChatReactionResponse, type: String, callCid: String) {
        self.createdAt = createdAt
        
        self.reaction = reaction
        
        self.type = type
        
        self.callCid = callCid
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case reaction
        
        case type
        
        case callCid = "call_cid"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(callCid, forKey: .callCid)
    }
}
