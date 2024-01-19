//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallResponse: Codable, Hashable {
    public var team: String?
    
    public var thumbnails: StreamChatThumbnailResponse?
    
    public var type: String
    
    public var updatedAt: Date
    
    public var createdBy: StreamChatUserResponse
    
    public var egress: StreamChatEgressResponse
    
    public var ingress: StreamChatCallIngressResponse
    
    public var recording: Bool
    
    public var endedAt: Date?
    
    public var startsAt: Date?
    
    public var backstage: Bool
    
    public var blockedUserIds: [String]
    
    public var currentSessionId: String
    
    public var transcribing: Bool
    
    public var session: StreamChatCallSessionResponse?
    
    public var settings: StreamChatCallSettingsResponse
    
    public var cid: String
    
    public var createdAt: Date
    
    public var custom: [String: RawJSON]
    
    public var id: String
    
    public init(team: String?, thumbnails: StreamChatThumbnailResponse?, type: String, updatedAt: Date, createdBy: StreamChatUserResponse, egress: StreamChatEgressResponse, ingress: StreamChatCallIngressResponse, recording: Bool, endedAt: Date?, startsAt: Date?, backstage: Bool, blockedUserIds: [String], currentSessionId: String, transcribing: Bool, session: StreamChatCallSessionResponse?, settings: StreamChatCallSettingsResponse, cid: String, createdAt: Date, custom: [String: RawJSON], id: String) {
        self.team = team
        
        self.thumbnails = thumbnails
        
        self.type = type
        
        self.updatedAt = updatedAt
        
        self.createdBy = createdBy
        
        self.egress = egress
        
        self.ingress = ingress
        
        self.recording = recording
        
        self.endedAt = endedAt
        
        self.startsAt = startsAt
        
        self.backstage = backstage
        
        self.blockedUserIds = blockedUserIds
        
        self.currentSessionId = currentSessionId
        
        self.transcribing = transcribing
        
        self.session = session
        
        self.settings = settings
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.custom = custom
        
        self.id = id
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case team
        
        case thumbnails
        
        case type
        
        case updatedAt = "updated_at"
        
        case createdBy = "created_by"
        
        case egress
        
        case ingress
        
        case recording
        
        case endedAt = "ended_at"
        
        case startsAt = "starts_at"
        
        case backstage
        
        case blockedUserIds = "blocked_user_ids"
        
        case currentSessionId = "current_session_id"
        
        case transcribing
        
        case session
        
        case settings
        
        case cid
        
        case createdAt = "created_at"
        
        case custom
        
        case id
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(thumbnails, forKey: .thumbnails)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(egress, forKey: .egress)
        
        try container.encode(ingress, forKey: .ingress)
        
        try container.encode(recording, forKey: .recording)
        
        try container.encode(endedAt, forKey: .endedAt)
        
        try container.encode(startsAt, forKey: .startsAt)
        
        try container.encode(backstage, forKey: .backstage)
        
        try container.encode(blockedUserIds, forKey: .blockedUserIds)
        
        try container.encode(currentSessionId, forKey: .currentSessionId)
        
        try container.encode(transcribing, forKey: .transcribing)
        
        try container.encode(session, forKey: .session)
        
        try container.encode(settings, forKey: .settings)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(id, forKey: .id)
    }
}
