//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelResponse: Codable, Hashable {
    public var lastMessageAt: Date?
    
    public var id: String
    
    public var deletedAt: Date?
    
    public var disabled: Bool
    
    public var hidden: Bool?
    
    public var updatedAt: Date
    
    public var memberCount: Int?
    
    public var muted: Bool?
    
    public var autoTranslationLanguage: String?
    
    public var frozen: Bool
    
    public var muteExpiresAt: Date?
    
    public var autoTranslationEnabled: Bool?
    
    public var createdBy: StreamChatUserObject?
    
    public var hideMessagesBefore: Date?
    
    public var custom: [String: RawJSON]?
    
    public var config: StreamChatChannelConfigWithInfo?
    
    public var ownCapabilities: [String]?
    
    public var members: [StreamChatChannelMember?]?
    
    public var team: String?
    
    public var truncatedAt: Date?
    
    public var cid: String
    
    public var cooldown: Int?
    
    public var createdAt: Date
    
    public var truncatedBy: StreamChatUserObject?
    
    public var type: String
    
    public init(lastMessageAt: Date?, id: String, deletedAt: Date?, disabled: Bool, hidden: Bool?, updatedAt: Date, memberCount: Int?, muted: Bool?, autoTranslationLanguage: String?, frozen: Bool, muteExpiresAt: Date?, autoTranslationEnabled: Bool?, createdBy: StreamChatUserObject?, hideMessagesBefore: Date?, custom: [String: RawJSON], config: StreamChatChannelConfigWithInfo?, ownCapabilities: [String]?, members: [StreamChatChannelMember?]?, team: String?, truncatedAt: Date?, cid: String, cooldown: Int?, createdAt: Date, truncatedBy: StreamChatUserObject?, type: String) {
        self.lastMessageAt = lastMessageAt
        
        self.id = id
        
        self.deletedAt = deletedAt
        
        self.disabled = disabled
        
        self.hidden = hidden
        
        self.updatedAt = updatedAt
        
        self.memberCount = memberCount
        
        self.muted = muted
        
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.frozen = frozen
        
        self.muteExpiresAt = muteExpiresAt
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.createdBy = createdBy
        
        self.hideMessagesBefore = hideMessagesBefore
        
        self.custom = custom
        
        self.config = config
        
        self.ownCapabilities = ownCapabilities
        
        self.members = members
        
        self.team = team
        
        self.truncatedAt = truncatedAt
        
        self.cid = cid
        
        self.cooldown = cooldown
        
        self.createdAt = createdAt
        
        self.truncatedBy = truncatedBy
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case lastMessageAt = "last_message_at"
        
        case id
        
        case deletedAt = "deleted_at"
        
        case disabled
        
        case hidden
        
        case updatedAt = "updated_at"
        
        case memberCount = "member_count"
        
        case muted
        
        case autoTranslationLanguage = "auto_translation_language"
        
        case frozen
        
        case muteExpiresAt = "mute_expires_at"
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case createdBy = "created_by"
        
        case hideMessagesBefore = "hide_messages_before"
        
        case custom = "Custom"
        
        case config
        
        case ownCapabilities = "own_capabilities"
        
        case members
        
        case team
        
        case truncatedAt = "truncated_at"
        
        case cid
        
        case cooldown
        
        case createdAt = "created_at"
        
        case truncatedBy = "truncated_by"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(lastMessageAt, forKey: .lastMessageAt)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(hidden, forKey: .hidden)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(memberCount, forKey: .memberCount)
        
        try container.encode(muted, forKey: .muted)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(muteExpiresAt, forKey: .muteExpiresAt)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(config, forKey: .config)
        
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(truncatedAt, forKey: .truncatedAt)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(truncatedBy, forKey: .truncatedBy)
        
        try container.encode(type, forKey: .type)
    }
}
