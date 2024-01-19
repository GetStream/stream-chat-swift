//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallSessionResponse: Codable, Hashable {
    public var acceptedBy: [String: RawJSON]
    
    public var id: String
    
    public var participantsCountByRole: [String: RawJSON]
    
    public var startedAt: Date?
    
    public var endedAt: Date?
    
    public var liveEndedAt: Date?
    
    public var liveStartedAt: Date?
    
    public var participants: [StreamChatCallParticipantResponse]
    
    public var rejectedBy: [String: RawJSON]
    
    public init(acceptedBy: [String: RawJSON], id: String, participantsCountByRole: [String: RawJSON], startedAt: Date?, endedAt: Date?, liveEndedAt: Date?, liveStartedAt: Date?, participants: [StreamChatCallParticipantResponse], rejectedBy: [String: RawJSON]) {
        self.acceptedBy = acceptedBy
        
        self.id = id
        
        self.participantsCountByRole = participantsCountByRole
        
        self.startedAt = startedAt
        
        self.endedAt = endedAt
        
        self.liveEndedAt = liveEndedAt
        
        self.liveStartedAt = liveStartedAt
        
        self.participants = participants
        
        self.rejectedBy = rejectedBy
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case acceptedBy = "accepted_by"
        
        case id
        
        case participantsCountByRole = "participants_count_by_role"
        
        case startedAt = "started_at"
        
        case endedAt = "ended_at"
        
        case liveEndedAt = "live_ended_at"
        
        case liveStartedAt = "live_started_at"
        
        case participants
        
        case rejectedBy = "rejected_by"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(acceptedBy, forKey: .acceptedBy)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(participantsCountByRole, forKey: .participantsCountByRole)
        
        try container.encode(startedAt, forKey: .startedAt)
        
        try container.encode(endedAt, forKey: .endedAt)
        
        try container.encode(liveEndedAt, forKey: .liveEndedAt)
        
        try container.encode(liveStartedAt, forKey: .liveStartedAt)
        
        try container.encode(participants, forKey: .participants)
        
        try container.encode(rejectedBy, forKey: .rejectedBy)
    }
}
