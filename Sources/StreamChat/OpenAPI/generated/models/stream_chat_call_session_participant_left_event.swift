//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallSessionParticipantLeftEvent: Codable, Hashable {
    public var sessionId: String
    
    public var type: String
    
    public var callCid: String
    
    public var createdAt: String
    
    public var participant: StreamChatCallParticipantResponse
    
    public init(sessionId: String, type: String, callCid: String, createdAt: String, participant: StreamChatCallParticipantResponse) {
        self.sessionId = sessionId
        
        self.type = type
        
        self.callCid = callCid
        
        self.createdAt = createdAt
        
        self.participant = participant
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case sessionId = "session_id"
        
        case type
        
        case callCid = "call_cid"
        
        case createdAt = "created_at"
        
        case participant
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(sessionId, forKey: .sessionId)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(participant, forKey: .participant)
    }
}
