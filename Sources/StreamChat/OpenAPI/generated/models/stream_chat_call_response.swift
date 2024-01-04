//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallResponse: Codable, Hashable {
    public var egress: StreamChatEgressResponse
    
    public var id: String
    
    public var recording: Bool
    
    public var cid: String
    
    public var blockedUserIds: [String]
    
    public var startsAt: String?
    
    public var updatedAt: String
    
    public var backstage: Bool
    
    public var createdBy: StreamChatUserResponse
    
    public var custom: [String: RawJSON]
    
    public var endedAt: String?
    
    public var team: String?
    
    public var thumbnails: StreamChatThumbnailResponse?
    
    public var transcribing: Bool
    
    public var createdAt: String
    
    public var ingress: StreamChatCallIngressResponse
    
    public var session: StreamChatCallSessionResponse?
    
    public var settings: StreamChatCallSettingsResponse
    
    public var type: String
    
    public var currentSessionId: String
    
    public init(egress: StreamChatEgressResponse, id: String, recording: Bool, cid: String, blockedUserIds: [String], startsAt: String?, updatedAt: String, backstage: Bool, createdBy: StreamChatUserResponse, custom: [String: RawJSON], endedAt: String?, team: String?, thumbnails: StreamChatThumbnailResponse?, transcribing: Bool, createdAt: String, ingress: StreamChatCallIngressResponse, session: StreamChatCallSessionResponse?, settings: StreamChatCallSettingsResponse, type: String, currentSessionId: String) {
        self.egress = egress
        
        self.id = id
        
        self.recording = recording
        
        self.cid = cid
        
        self.blockedUserIds = blockedUserIds
        
        self.startsAt = startsAt
        
        self.updatedAt = updatedAt
        
        self.backstage = backstage
        
        self.createdBy = createdBy
        
        self.custom = custom
        
        self.endedAt = endedAt
        
        self.team = team
        
        self.thumbnails = thumbnails
        
        self.transcribing = transcribing
        
        self.createdAt = createdAt
        
        self.ingress = ingress
        
        self.session = session
        
        self.settings = settings
        
        self.type = type
        
        self.currentSessionId = currentSessionId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case egress
        
        case id
        
        case recording
        
        case cid
        
        case blockedUserIds = "blocked_user_ids"
        
        case startsAt = "starts_at"
        
        case updatedAt = "updated_at"
        
        case backstage
        
        case createdBy = "created_by"
        
        case custom
        
        case endedAt = "ended_at"
        
        case team
        
        case thumbnails
        
        case transcribing
        
        case createdAt = "created_at"
        
        case ingress
        
        case session
        
        case settings
        
        case type
        
        case currentSessionId = "current_session_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(egress, forKey: .egress)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(recording, forKey: .recording)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(blockedUserIds, forKey: .blockedUserIds)
        
        try container.encode(startsAt, forKey: .startsAt)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(backstage, forKey: .backstage)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(endedAt, forKey: .endedAt)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(thumbnails, forKey: .thumbnails)
        
        try container.encode(transcribing, forKey: .transcribing)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(ingress, forKey: .ingress)
        
        try container.encode(session, forKey: .session)
        
        try container.encode(settings, forKey: .settings)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(currentSessionId, forKey: .currentSessionId)
    }
}
