//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallHLSBroadcastingFailedEvent: Codable, Hashable {
    public var callCid: String
    
    public var createdAt: Date
    
    public var type: String
    
    public init(callCid: String, createdAt: Date, type: String) {
        self.callCid = callCid
        
        self.createdAt = createdAt
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        
        case createdAt = "created_at"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
    }
}
