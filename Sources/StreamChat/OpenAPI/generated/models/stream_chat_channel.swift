//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannel: Codable, Hashable {
    public var custom: [String: RawJSON]
    
    public var cid: String
    
    public var configOverrides: StreamChatChannelConfig?
    
    public var id: String
    
    public var lastMessageAt: String?
    
    public var members: [StreamChatChannelMember?]?
    
    public var autoTranslationEnabled: Bool?
    
    public var createdBy: StreamChatUserObject?
    
    public var deletedAt: String?
    
    public var disabled: Bool
    
    public var autoTranslationLanguage: String
    
    public var config: StreamChatChannelConfig?
    
    public var cooldown: Int?
    
    public var team: String?
    
    public var type: String
    
    public var createdAt: String
    
    public var frozen: Bool
    
    public var invites: [StreamChatChannelMember?]?
    
    public var memberCount: Int?
    
    public var truncatedBy: StreamChatUserObject?
    
    public var updatedAt: String
    
    public init(custom: [String: RawJSON], cid: String, configOverrides: StreamChatChannelConfig?, id: String, lastMessageAt: String?, members: [StreamChatChannelMember?]?, autoTranslationEnabled: Bool?, createdBy: StreamChatUserObject?, deletedAt: String?, disabled: Bool, autoTranslationLanguage: String, config: StreamChatChannelConfig?, cooldown: Int?, team: String?, type: String, createdAt: String, frozen: Bool, invites: [StreamChatChannelMember?]?, memberCount: Int?, truncatedBy: StreamChatUserObject?, updatedAt: String) {
        self.custom = custom
        
        self.cid = cid
        
        self.configOverrides = configOverrides
        
        self.id = id
        
        self.lastMessageAt = lastMessageAt
        
        self.members = members
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.createdBy = createdBy
        
        self.deletedAt = deletedAt
        
        self.disabled = disabled
        
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.config = config
        
        self.cooldown = cooldown
        
        self.team = team
        
        self.type = type
        
        self.createdAt = createdAt
        
        self.frozen = frozen
        
        self.invites = invites
        
        self.memberCount = memberCount
        
        self.truncatedBy = truncatedBy
        
        self.updatedAt = updatedAt
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom = "Custom"
        
        case cid
        
        case configOverrides = "config_overrides"
        
        case id
        
        case lastMessageAt = "last_message_at"
        
        case members
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case createdBy = "created_by"
        
        case deletedAt = "deleted_at"
        
        case disabled
        
        case autoTranslationLanguage = "auto_translation_language"
        
        case config
        
        case cooldown
        
        case team
        
        case type
        
        case createdAt = "created_at"
        
        case frozen
        
        case invites
        
        case memberCount = "member_count"
        
        case truncatedBy = "truncated_by"
        
        case updatedAt = "updated_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(configOverrides, forKey: .configOverrides)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(lastMessageAt, forKey: .lastMessageAt)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(config, forKey: .config)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(invites, forKey: .invites)
        
        try container.encode(memberCount, forKey: .memberCount)
        
        try container.encode(truncatedBy, forKey: .truncatedBy)
        
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
