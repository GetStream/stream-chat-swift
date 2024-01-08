//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelResponse: Codable, Hashable {
    public var muted: Bool?
    
    public var truncatedAt: String?
    
    public var cooldown: Int?
    
    public var frozen: Bool
    
    public var id: String
    
    public var muteExpiresAt: String?
    
    public var config: StreamChatChannelConfigWithInfo?
    
    public var createdBy: StreamChatUserObject?
    
    public var deletedAt: String?
    
    public var disabled: Bool
    
    public var memberCount: Int?
    
    public var members: [StreamChatChannelMember?]?
    
    public var hidden: Bool?
    
    public var cid: String
    
    public var hideMessagesBefore: String?
    
    public var ownCapabilities: [String]?
    
    public var team: String?
    
    public var autoTranslationEnabled: Bool?
    
    public var createdAt: String?
    
    public var autoTranslationLanguage: String?
    
    public var type: String
    
    public var lastMessageAt: String?
    
    public var truncatedBy: StreamChatUserObject?
    
    public var custom: [String: RawJSON]
    
    public var updatedAt: String?
    
    public init(muted: Bool?, truncatedAt: String?, cooldown: Int?, frozen: Bool, id: String, muteExpiresAt: String?, config: StreamChatChannelConfigWithInfo?, createdBy: StreamChatUserObject?, deletedAt: String?, disabled: Bool, memberCount: Int?, members: [StreamChatChannelMember?]?, hidden: Bool?, cid: String, hideMessagesBefore: String?, ownCapabilities: [String]?, team: String?, autoTranslationEnabled: Bool?, createdAt: String?, autoTranslationLanguage: String?, type: String, lastMessageAt: String?, truncatedBy: StreamChatUserObject?, custom: [String: RawJSON], updatedAt: String?) {
        self.muted = muted
        
        self.truncatedAt = truncatedAt
        
        self.cooldown = cooldown
        
        self.frozen = frozen
        
        self.id = id
        
        self.muteExpiresAt = muteExpiresAt
        
        self.config = config
        
        self.createdBy = createdBy
        
        self.deletedAt = deletedAt
        
        self.disabled = disabled
        
        self.memberCount = memberCount
        
        self.members = members
        
        self.hidden = hidden
        
        self.cid = cid
        
        self.hideMessagesBefore = hideMessagesBefore
        
        self.ownCapabilities = ownCapabilities
        
        self.team = team
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.createdAt = createdAt
        
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.type = type
        
        self.lastMessageAt = lastMessageAt
        
        self.truncatedBy = truncatedBy
        
        self.custom = custom
        
        self.updatedAt = updatedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case muted
        
        case truncatedAt = "truncated_at"
        
        case cooldown
        
        case frozen
        
        case id
        
        case muteExpiresAt = "mute_expires_at"
        
        case config
        
        case createdBy = "created_by"
        
        case deletedAt = "deleted_at"
        
        case disabled
        
        case memberCount = "member_count"
        
        case members
        
        case hidden
        
        case cid
        
        case hideMessagesBefore = "hide_messages_before"
        
        case ownCapabilities = "own_capabilities"
        
        case team
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case createdAt = "created_at"
        
        case autoTranslationLanguage = "auto_translation_language"
        
        case type
        
        case lastMessageAt = "last_message_at"
        
        case truncatedBy = "truncated_by"
        
        case custom = "Custom"
        
        case updatedAt = "updated_at"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(muted, forKey: .muted)
        
        try container.encode(truncatedAt, forKey: .truncatedAt)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(muteExpiresAt, forKey: .muteExpiresAt)
        
        try container.encode(config, forKey: .config)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(memberCount, forKey: .memberCount)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(hidden, forKey: .hidden)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(lastMessageAt, forKey: .lastMessageAt)
        
        try container.encode(truncatedBy, forKey: .truncatedBy)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
