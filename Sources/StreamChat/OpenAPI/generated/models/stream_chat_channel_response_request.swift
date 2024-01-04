//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelResponseRequest: Codable, Hashable {
    public var type: String?
    
    public var memberCount: Int?
    
    public var createdBy: StreamChatUserObjectRequest?
    
    public var members: [StreamChatChannelMemberRequest?]?
    
    public var truncatedAt: String?
    
    public var autoTranslationLanguage: String?
    
    public var cid: String?
    
    public var config: StreamChatChannelConfigWithInfoRequest?
    
    public var team: String?
    
    public var autoTranslationEnabled: Bool?
    
    public var hideMessagesBefore: String?
    
    public var cooldown: Int?
    
    public var frozen: Bool?
    
    public var hidden: Bool?
    
    public var ownCapabilities: [String]?
    
    public var custom: [String: RawJSON]?
    
    public var id: String?
    
    public var muted: Bool?
    
    public var updatedAt: String?
    
    public var deletedAt: String?
    
    public var disabled: Bool?
    
    public var lastMessageAt: String?
    
    public var muteExpiresAt: String?
    
    public var truncatedBy: StreamChatUserObjectRequest?
    
    public var createdAt: String?
    
    public init(type: String?, memberCount: Int?, createdBy: StreamChatUserObjectRequest?, members: [StreamChatChannelMemberRequest?]?, truncatedAt: String?, autoTranslationLanguage: String?, cid: String?, config: StreamChatChannelConfigWithInfoRequest?, team: String?, autoTranslationEnabled: Bool?, hideMessagesBefore: String?, cooldown: Int?, frozen: Bool?, hidden: Bool?, ownCapabilities: [String]?, custom: [String: RawJSON]?, id: String?, muted: Bool?, updatedAt: String?, deletedAt: String?, disabled: Bool?, lastMessageAt: String?, muteExpiresAt: String?, truncatedBy: StreamChatUserObjectRequest?, createdAt: String?) {
        self.type = type
        
        self.memberCount = memberCount
        
        self.createdBy = createdBy
        
        self.members = members
        
        self.truncatedAt = truncatedAt
        
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.cid = cid
        
        self.config = config
        
        self.team = team
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.hideMessagesBefore = hideMessagesBefore
        
        self.cooldown = cooldown
        
        self.frozen = frozen
        
        self.hidden = hidden
        
        self.ownCapabilities = ownCapabilities
        
        self.custom = custom
        
        self.id = id
        
        self.muted = muted
        
        self.updatedAt = updatedAt
        
        self.deletedAt = deletedAt
        
        self.disabled = disabled
        
        self.lastMessageAt = lastMessageAt
        
        self.muteExpiresAt = muteExpiresAt
        
        self.truncatedBy = truncatedBy
        
        self.createdAt = createdAt
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case memberCount = "member_count"
        
        case createdBy = "created_by"
        
        case members
        
        case truncatedAt = "truncated_at"
        
        case autoTranslationLanguage = "auto_translation_language"
        
        case cid
        
        case config
        
        case team
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case hideMessagesBefore = "hide_messages_before"
        
        case cooldown
        
        case frozen
        
        case hidden
        
        case ownCapabilities = "own_capabilities"
        
        case custom = "Custom"
        
        case id
        
        case muted
        
        case updatedAt = "updated_at"
        
        case deletedAt = "deleted_at"
        
        case disabled
        
        case lastMessageAt = "last_message_at"
        
        case muteExpiresAt = "mute_expires_at"
        
        case truncatedBy = "truncated_by"
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(memberCount, forKey: .memberCount)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(truncatedAt, forKey: .truncatedAt)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(config, forKey: .config)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(hidden, forKey: .hidden)
        
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(muted, forKey: .muted)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(lastMessageAt, forKey: .lastMessageAt)
        
        try container.encode(muteExpiresAt, forKey: .muteExpiresAt)
        
        try container.encode(truncatedBy, forKey: .truncatedBy)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}
