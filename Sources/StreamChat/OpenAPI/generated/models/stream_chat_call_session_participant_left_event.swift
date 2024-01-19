//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallSessionParticipantLeftEvent: Codable, Hashable {
    public var callCid: String
    
    public var createdAt: Date
    
    public var participant: StreamChatCallParticipantResponse
    
    public var sessionId: String
    
    public var type: String
    
    public init(callCid: String, createdAt: Date, participant: StreamChatCallParticipantResponse, sessionId: String, type: String) {
        self.callCid = callCid
        
        self.createdAt = createdAt
        
        self.participant = participant
        
        self.sessionId = sessionId
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        
        case createdAt = "created_at"
        
        case participant
        
        case sessionId = "session_id"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(participant, forKey: .participant)
        
        try container.encode(sessionId, forKey: .sessionId)
        
        try container.encode(type, forKey: .type)
    }
}
