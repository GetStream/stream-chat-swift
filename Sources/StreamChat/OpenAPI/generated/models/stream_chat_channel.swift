//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannel: Codable, Hashable {
    public var autoTranslationLanguage: String
    
    public var createdBy: StreamChatUserObject?
    
    public var deletedAt: Date?
    
    public var disabled: Bool
    
    public var lastMessageAt: Date?
    
    public var memberCount: Int?
    
    public var truncatedBy: StreamChatUserObject?
    
    public var cid: String
    
    public var config: StreamChatChannelConfig?
    
    public var configOverrides: StreamChatChannelConfig?
    
    public var cooldown: Int?
    
    public var invites: [StreamChatChannelMember?]?
    
    public var updatedAt: Date
    
    public var autoTranslationEnabled: Bool?
    
    public var createdAt: Date
    
    public var frozen: Bool
    
    public var members: [StreamChatChannelMember?]?
    
    public var team: String?
    
    public var type: String
    
    public var custom: [String: RawJSON]
    
    public var id: String
    
    public init(autoTranslationLanguage: String, createdBy: StreamChatUserObject?, deletedAt: Date?, disabled: Bool, lastMessageAt: Date?, memberCount: Int?, truncatedBy: StreamChatUserObject?, cid: String, config: StreamChatChannelConfig?, configOverrides: StreamChatChannelConfig?, cooldown: Int?, invites: [StreamChatChannelMember?]?, updatedAt: Date, autoTranslationEnabled: Bool?, createdAt: Date, frozen: Bool, members: [StreamChatChannelMember?]?, team: String?, type: String, custom: [String: RawJSON], id: String) {
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.createdBy = createdBy
        
        self.deletedAt = deletedAt
        
        self.disabled = disabled
        
        self.lastMessageAt = lastMessageAt
        
        self.memberCount = memberCount
        
        self.truncatedBy = truncatedBy
        
        self.cid = cid
        
        self.config = config
        
        self.configOverrides = configOverrides
        
        self.cooldown = cooldown
        
        self.invites = invites
        
        self.updatedAt = updatedAt
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.createdAt = createdAt
        
        self.frozen = frozen
        
        self.members = members
        
        self.team = team
        
        self.type = type
        
        self.custom = custom
        
        self.id = id
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoTranslationLanguage = "auto_translation_language"
        
        case createdBy = "created_by"
        
        case deletedAt = "deleted_at"
        
        case disabled
        
        case lastMessageAt = "last_message_at"
        
        case memberCount = "member_count"
        
        case truncatedBy = "truncated_by"
        
        case cid
        
        case config
        
        case configOverrides = "config_overrides"
        
        case cooldown
        
        case invites
        
        case updatedAt = "updated_at"
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case createdAt = "created_at"
        
        case frozen
        
        case members
        
        case team
        
        case type
        
        case custom = "Custom"
        
        case id
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(lastMessageAt, forKey: .lastMessageAt)
        
        try container.encode(memberCount, forKey: .memberCount)
        
        try container.encode(truncatedBy, forKey: .truncatedBy)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(config, forKey: .config)
        
        try container.encode(configOverrides, forKey: .configOverrides)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(invites, forKey: .invites)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(id, forKey: .id)
    }
}
