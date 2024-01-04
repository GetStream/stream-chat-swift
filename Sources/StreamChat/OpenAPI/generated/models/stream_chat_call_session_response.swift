//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallSessionResponse: Codable, Hashable {
    public var endedAt: String?
    
    public var id: String
    
    public var liveEndedAt: String?
    
    public var liveStartedAt: String?
    
    public var rejectedBy: [String: RawJSON]
    
    public var startedAt: String?
    
    public var acceptedBy: [String: RawJSON]
    
    public var participantsCountByRole: [String: RawJSON]
    
    public var participants: [StreamChatCallParticipantResponse]
    
    public init(endedAt: String?, id: String, liveEndedAt: String?, liveStartedAt: String?, rejectedBy: [String: RawJSON], startedAt: String?, acceptedBy: [String: RawJSON], participantsCountByRole: [String: RawJSON], participants: [StreamChatCallParticipantResponse]) {
        self.endedAt = endedAt
        
        self.id = id
        
        self.liveEndedAt = liveEndedAt
        
        self.liveStartedAt = liveStartedAt
        
        self.rejectedBy = rejectedBy
        
        self.startedAt = startedAt
        
        self.acceptedBy = acceptedBy
        
        self.participantsCountByRole = participantsCountByRole
        
        self.participants = participants
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case endedAt = "ended_at"
        
        case id
        
        case liveEndedAt = "live_ended_at"
        
        case liveStartedAt = "live_started_at"
        
        case rejectedBy = "rejected_by"
        
        case startedAt = "started_at"
        
        case acceptedBy = "accepted_by"
        
        case participantsCountByRole = "participants_count_by_role"
        
        case participants
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(endedAt, forKey: .endedAt)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(liveEndedAt, forKey: .liveEndedAt)
        
        try container.encode(liveStartedAt, forKey: .liveStartedAt)
        
        try container.encode(rejectedBy, forKey: .rejectedBy)
        
        try container.encode(startedAt, forKey: .startedAt)
        
        try container.encode(acceptedBy, forKey: .acceptedBy)
        
        try container.encode(participantsCountByRole, forKey: .participantsCountByRole)
        
        try container.encode(participants, forKey: .participants)
    }
}
