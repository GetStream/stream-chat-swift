//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallRecordingStoppedEvent: Codable, Hashable {
    public var type: String
    
    public var callCid: String
    
    public var createdAt: String
    
    public init(type: String, callCid: String, createdAt: String) {
        self.type = type
        
        self.callCid = callCid
        
        self.createdAt = createdAt
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case callCid = "call_cid"
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}
