//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelResponse: Codable, Hashable {
    public var truncatedBy: StreamChatUserObject?
    
    public var updatedAt: String?
    
    public var autoTranslationLanguage: String?
    
    public var disabled: Bool
    
    public var members: [StreamChatChannelMember?]?
    
    public var id: String
    
    public var muteExpiresAt: String?
    
    public var cid: String
    
    public var createdAt: String?
    
    public var createdBy: StreamChatUserObject?
    
    public var memberCount: Int?
    
    public var custom: [String: RawJSON]
    
    public var cooldown: Int?
    
    public var team: String?
    
    public var type: String
    
    public var ownCapabilities: [String]?
    
    public var deletedAt: String?
    
    public var hideMessagesBefore: String?
    
    public var muted: Bool?
    
    public var truncatedAt: String?
    
    public var autoTranslationEnabled: Bool?
    
    public var frozen: Bool
    
    public var hidden: Bool?
    
    public var lastMessageAt: String?
    
    public var config: StreamChatChannelConfigWithInfo?
    
    public init(truncatedBy: StreamChatUserObject?, updatedAt: String?, autoTranslationLanguage: String?, disabled: Bool, members: [StreamChatChannelMember?]?, id: String, muteExpiresAt: String?, cid: String, createdAt: String?, createdBy: StreamChatUserObject?, memberCount: Int?, custom: [String: RawJSON], cooldown: Int?, team: String?, type: String, ownCapabilities: [String]?, deletedAt: String?, hideMessagesBefore: String?, muted: Bool?, truncatedAt: String?, autoTranslationEnabled: Bool?, frozen: Bool, hidden: Bool?, lastMessageAt: String?, config: StreamChatChannelConfigWithInfo?) {
        self.truncatedBy = truncatedBy
        
        self.updatedAt = updatedAt
        
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.disabled = disabled
        
        self.members = members
        
        self.id = id
        
        self.muteExpiresAt = muteExpiresAt
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.createdBy = createdBy
        
        self.memberCount = memberCount
        
        self.custom = custom
        
        self.cooldown = cooldown
        
        self.team = team
        
        self.type = type
        
        self.ownCapabilities = ownCapabilities
        
        self.deletedAt = deletedAt
        
        self.hideMessagesBefore = hideMessagesBefore
        
        self.muted = muted
        
        self.truncatedAt = truncatedAt
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.frozen = frozen
        
        self.hidden = hidden
        
        self.lastMessageAt = lastMessageAt
        
        self.config = config
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case truncatedBy = "truncated_by"
        
        case updatedAt = "updated_at"
        
        case autoTranslationLanguage = "auto_translation_language"
        
        case disabled
        
        case members
        
        case id
        
        case muteExpiresAt = "mute_expires_at"
        
        case cid
        
        case createdAt = "created_at"
        
        case createdBy = "created_by"
        
        case memberCount = "member_count"
        
        case custom = "Custom"
        
        case cooldown
        
        case team
        
        case type
        
        case ownCapabilities = "own_capabilities"
        
        case deletedAt = "deleted_at"
        
        case hideMessagesBefore = "hide_messages_before"
        
        case muted
        
        case truncatedAt = "truncated_at"
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case frozen
        
        case hidden
        
        case lastMessageAt = "last_message_at"
        
        case config
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(truncatedBy, forKey: .truncatedBy)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(muteExpiresAt, forKey: .muteExpiresAt)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(memberCount, forKey: .memberCount)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(muted, forKey: .muted)
        
        try container.encode(truncatedAt, forKey: .truncatedAt)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(hidden, forKey: .hidden)
        
        try container.encode(lastMessageAt, forKey: .lastMessageAt)
        
        try container.encode(config, forKey: .config)
    }
}
