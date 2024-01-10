//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannel: Codable, Hashable {
    public var autoTranslationEnabled: Bool?
    
    public var config: StreamChatChannelConfig?
    
    public var updatedAt: String
    
    public var cooldown: Int?
    
    public var createdAt: String
    
    public var createdBy: StreamChatUserObject?
    
    public var frozen: Bool
    
    public var memberCount: Int?
    
    public var members: [StreamChatChannelMember?]?
    
    public var team: String?
    
    public var type: String
    
    public var custom: [String: RawJSON]
    
    public var cid: String
    
    public var invites: [StreamChatChannelMember?]?
    
    public var lastMessageAt: String?
    
    public var autoTranslationLanguage: String
    
    public var configOverrides: StreamChatChannelConfig?
    
    public var deletedAt: String?
    
    public var disabled: Bool
    
    public var id: String
    
    public var truncatedBy: StreamChatUserObject?
    
    public init(autoTranslationEnabled: Bool?, config: StreamChatChannelConfig?, updatedAt: String, cooldown: Int?, createdAt: String, createdBy: StreamChatUserObject?, frozen: Bool, memberCount: Int?, members: [StreamChatChannelMember?]?, team: String?, type: String, custom: [String: RawJSON], cid: String, invites: [StreamChatChannelMember?]?, lastMessageAt: String?, autoTranslationLanguage: String, configOverrides: StreamChatChannelConfig?, deletedAt: String?, disabled: Bool, id: String, truncatedBy: StreamChatUserObject?) {
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.config = config
        
        self.updatedAt = updatedAt
        
        self.cooldown = cooldown
        
        self.createdAt = createdAt
        
        self.createdBy = createdBy
        
        self.frozen = frozen
        
        self.memberCount = memberCount
        
        self.members = members
        
        self.team = team
        
        self.type = type
        
        self.custom = custom
        
        self.cid = cid
        
        self.invites = invites
        
        self.lastMessageAt = lastMessageAt
        
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.configOverrides = configOverrides
        
        self.deletedAt = deletedAt
        
        self.disabled = disabled
        
        self.id = id
        
        self.truncatedBy = truncatedBy
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case config
        
        case updatedAt = "updated_at"
        
        case cooldown
        
        case createdAt = "created_at"
        
        case createdBy = "created_by"
        
        case frozen
        
        case memberCount = "member_count"
        
        case members
        
        case team
        
        case type
        
        case custom = "Custom"
        
        case cid
        
        case invites
        
        case lastMessageAt = "last_message_at"
        
        case autoTranslationLanguage = "auto_translation_language"
        
        case configOverrides = "config_overrides"
        
        case deletedAt = "deleted_at"
        
        case disabled
        
        case id
        
        case truncatedBy = "truncated_by"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(config, forKey: .config)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(memberCount, forKey: .memberCount)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(invites, forKey: .invites)
        
        try container.encode(lastMessageAt, forKey: .lastMessageAt)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(configOverrides, forKey: .configOverrides)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(truncatedBy, forKey: .truncatedBy)
    }
}
