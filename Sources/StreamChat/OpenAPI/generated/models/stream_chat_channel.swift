//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannel: Codable, Hashable {
    public var autoTranslationLanguage: String
    
    public var deletedAt: Date?
    
    public var id: String
    
    public var updatedAt: Date
    
    public var memberCount: Int?
    
    public var members: [StreamChatChannelMember?]?
    
    public var custom: [String: RawJSON]
    
    public var autoTranslationEnabled: Bool?
    
    public var cid: String
    
    public var cooldown: Int?
    
    public var invites: [StreamChatChannelMember?]?
    
    public var lastMessageAt: Date?
    
    public var team: String?
    
    public var truncatedBy: StreamChatUserObject?
    
    public var config: StreamChatChannelConfig?
    
    public var configOverrides: StreamChatChannelConfig?
    
    public var createdAt: Date
    
    public var disabled: Bool
    
    public var type: String
    
    public var createdBy: StreamChatUserObject?
    
    public var frozen: Bool
    
    public init(autoTranslationLanguage: String, deletedAt: Date?, id: String, updatedAt: Date, memberCount: Int?, members: [StreamChatChannelMember?]?, custom: [String: RawJSON], autoTranslationEnabled: Bool?, cid: String, cooldown: Int?, invites: [StreamChatChannelMember?]?, lastMessageAt: Date?, team: String?, truncatedBy: StreamChatUserObject?, config: StreamChatChannelConfig?, configOverrides: StreamChatChannelConfig?, createdAt: Date, disabled: Bool, type: String, createdBy: StreamChatUserObject?, frozen: Bool) {
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.deletedAt = deletedAt
        
        self.id = id
        
        self.updatedAt = updatedAt
        
        self.memberCount = memberCount
        
        self.members = members
        
        self.custom = custom
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.cid = cid
        
        self.cooldown = cooldown
        
        self.invites = invites
        
        self.lastMessageAt = lastMessageAt
        
        self.team = team
        
        self.truncatedBy = truncatedBy
        
        self.config = config
        
        self.configOverrides = configOverrides
        
        self.createdAt = createdAt
        
        self.disabled = disabled
        
        self.type = type
        
        self.createdBy = createdBy
        
        self.frozen = frozen
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoTranslationLanguage = "auto_translation_language"
        
        case deletedAt = "deleted_at"
        
        case id
        
        case updatedAt = "updated_at"
        
        case memberCount = "member_count"
        
        case members
        
        case custom = "Custom"
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case cid
        
        case cooldown
        
        case invites
        
        case lastMessageAt = "last_message_at"
        
        case team
        
        case truncatedBy = "truncated_by"
        
        case config
        
        case configOverrides = "config_overrides"
        
        case createdAt = "created_at"
        
        case disabled
        
        case type
        
        case createdBy = "created_by"
        
        case frozen
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(memberCount, forKey: .memberCount)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(invites, forKey: .invites)
        
        try container.encode(lastMessageAt, forKey: .lastMessageAt)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(truncatedBy, forKey: .truncatedBy)
        
        try container.encode(config, forKey: .config)
        
        try container.encode(configOverrides, forKey: .configOverrides)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(frozen, forKey: .frozen)
    }
}
