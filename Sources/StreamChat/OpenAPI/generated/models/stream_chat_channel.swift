//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannel: Codable, Hashable {
    public var autoTranslationLanguage: String
    
    public var cid: String
    
    public var config: StreamChatChannelConfig?
    
    public var configOverrides: StreamChatChannelConfig?
    
    public var createdBy: StreamChatUserObject?
    
    public var deletedAt: String?
    
    public var disabled: Bool
    
    public var truncatedBy: StreamChatUserObject?
    
    public var type: String
    
    public var autoTranslationEnabled: Bool?
    
    public var cooldown: Int?
    
    public var memberCount: Int?
    
    public var members: [StreamChatChannelMember?]?
    
    public var updatedAt: String
    
    public var custom: [String: RawJSON]
    
    public var createdAt: String
    
    public var frozen: Bool
    
    public var id: String
    
    public var invites: [StreamChatChannelMember?]?
    
    public var lastMessageAt: String?
    
    public var team: String?
    
    public init(autoTranslationLanguage: String, cid: String, config: StreamChatChannelConfig?, configOverrides: StreamChatChannelConfig?, createdBy: StreamChatUserObject?, deletedAt: String?, disabled: Bool, truncatedBy: StreamChatUserObject?, type: String, autoTranslationEnabled: Bool?, cooldown: Int?, memberCount: Int?, members: [StreamChatChannelMember?]?, updatedAt: String, custom: [String: RawJSON], createdAt: String, frozen: Bool, id: String, invites: [StreamChatChannelMember?]?, lastMessageAt: String?, team: String?) {
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.cid = cid
        
        self.config = config
        
        self.configOverrides = configOverrides
        
        self.createdBy = createdBy
        
        self.deletedAt = deletedAt
        
        self.disabled = disabled
        
        self.truncatedBy = truncatedBy
        
        self.type = type
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.cooldown = cooldown
        
        self.memberCount = memberCount
        
        self.members = members
        
        self.updatedAt = updatedAt
        
        self.custom = custom
        
        self.createdAt = createdAt
        
        self.frozen = frozen
        
        self.id = id
        
        self.invites = invites
        
        self.lastMessageAt = lastMessageAt
        
        self.team = team
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoTranslationLanguage = "auto_translation_language"
        
        case cid
        
        case config
        
        case configOverrides = "config_overrides"
        
        case createdBy = "created_by"
        
        case deletedAt = "deleted_at"
        
        case disabled
        
        case truncatedBy = "truncated_by"
        
        case type
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case cooldown
        
        case memberCount = "member_count"
        
        case members
        
        case updatedAt = "updated_at"
        
        case custom = "Custom"
        
        case createdAt = "created_at"
        
        case frozen
        
        case id
        
        case invites
        
        case lastMessageAt = "last_message_at"
        
        case team
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(config, forKey: .config)
        
        try container.encode(configOverrides, forKey: .configOverrides)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(truncatedBy, forKey: .truncatedBy)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(memberCount, forKey: .memberCount)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(invites, forKey: .invites)
        
        try container.encode(lastMessageAt, forKey: .lastMessageAt)
        
        try container.encode(team, forKey: .team)
    }
}
