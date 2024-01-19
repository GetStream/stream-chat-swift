//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelResponse: Codable, Hashable {
    public var cid: String
    
    public var createdAt: Date
    
    public var disabled: Bool
    
    public var team: String?
    
    public var truncatedBy: StreamChatUserObject?
    
    public var custom: [String: RawJSON]?
    
    public var autoTranslationLanguage: String?
    
    public var cooldown: Int?
    
    public var ownCapabilities: [String]?
    
    public var type: String
    
    public var createdBy: StreamChatUserObject?
    
    public var muteExpiresAt: Date?
    
    public var config: StreamChatChannelConfigWithInfo?
    
    public var members: [StreamChatChannelMember?]?
    
    public var muted: Bool?
    
    public var updatedAt: Date
    
    public var autoTranslationEnabled: Bool?
    
    public var deletedAt: Date?
    
    public var hideMessagesBefore: Date?
    
    public var id: String
    
    public var lastMessageAt: Date?
    
    public var frozen: Bool
    
    public var hidden: Bool?
    
    public var memberCount: Int?
    
    public var truncatedAt: Date?
    
    public init(cid: String, createdAt: Date, disabled: Bool, team: String?, truncatedBy: StreamChatUserObject?, custom: [String: RawJSON], autoTranslationLanguage: String?, cooldown: Int?, ownCapabilities: [String]?, type: String, createdBy: StreamChatUserObject?, muteExpiresAt: Date?, config: StreamChatChannelConfigWithInfo?, members: [StreamChatChannelMember?]?, muted: Bool?, updatedAt: Date, autoTranslationEnabled: Bool?, deletedAt: Date?, hideMessagesBefore: Date?, id: String, lastMessageAt: Date?, frozen: Bool, hidden: Bool?, memberCount: Int?, truncatedAt: Date?) {
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.disabled = disabled
        
        self.team = team
        
        self.truncatedBy = truncatedBy
        
        self.custom = custom
        
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.cooldown = cooldown
        
        self.ownCapabilities = ownCapabilities
        
        self.type = type
        
        self.createdBy = createdBy
        
        self.muteExpiresAt = muteExpiresAt
        
        self.config = config
        
        self.members = members
        
        self.muted = muted
        
        self.updatedAt = updatedAt
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.deletedAt = deletedAt
        
        self.hideMessagesBefore = hideMessagesBefore
        
        self.id = id
        
        self.lastMessageAt = lastMessageAt
        
        self.frozen = frozen
        
        self.hidden = hidden
        
        self.memberCount = memberCount
        
        self.truncatedAt = truncatedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case createdAt = "created_at"
        
        case disabled
        
        case team
        
        case truncatedBy = "truncated_by"
        
        case custom = "Custom"
        
        case autoTranslationLanguage = "auto_translation_language"
        
        case cooldown
        
        case ownCapabilities = "own_capabilities"
        
        case type
        
        case createdBy = "created_by"
        
        case muteExpiresAt = "mute_expires_at"
        
        case config
        
        case members
        
        case muted
        
        case updatedAt = "updated_at"
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case deletedAt = "deleted_at"
        
        case hideMessagesBefore = "hide_messages_before"
        
        case id
        
        case lastMessageAt = "last_message_at"
        
        case frozen
        
        case hidden
        
        case memberCount = "member_count"
        
        case truncatedAt = "truncated_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(truncatedBy, forKey: .truncatedBy)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(muteExpiresAt, forKey: .muteExpiresAt)
        
        try container.encode(config, forKey: .config)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(muted, forKey: .muted)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(lastMessageAt, forKey: .lastMessageAt)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(hidden, forKey: .hidden)
        
        try container.encode(memberCount, forKey: .memberCount)
        
        try container.encode(truncatedAt, forKey: .truncatedAt)
    }
}
