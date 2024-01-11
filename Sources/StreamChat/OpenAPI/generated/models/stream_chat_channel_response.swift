//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelResponse: Codable, Hashable {
    public var id: String
    
    public var custom: [String: RawJSON]?
    
    public var autoTranslationEnabled: Bool?
    
    public var createdAt: Date?
    
    public var disabled: Bool
    
    public var truncatedAt: Date?
    
    public var updatedAt: Date?
    
    public var autoTranslationLanguage: String?
    
    public var cooldown: Int?
    
    public var createdBy: StreamChatUserObject?
    
    public var memberCount: Int?
    
    public var ownCapabilities: [String]?
    
    public var cid: String
    
    public var frozen: Bool
    
    public var hideMessagesBefore: String?
    
    public var config: StreamChatChannelConfigWithInfo?
    
    public var deletedAt: Date?
    
    public var lastMessageAt: Date?
    
    public var muted: Bool?
    
    public var hidden: Bool?
    
    public var team: String?
    
    public var truncatedBy: StreamChatUserObject?
    
    public var muteExpiresAt: Date?
    
    public var type: String
    
    public var members: [StreamChatChannelMember?]?
    
    public init(id: String, custom: [String: RawJSON], autoTranslationEnabled: Bool?, createdAt: Date?, disabled: Bool, truncatedAt: Date?, updatedAt: Date?, autoTranslationLanguage: String?, cooldown: Int?, createdBy: StreamChatUserObject?, memberCount: Int?, ownCapabilities: [String]?, cid: String, frozen: Bool, hideMessagesBefore: String?, config: StreamChatChannelConfigWithInfo?, deletedAt: Date?, lastMessageAt: Date?, muted: Bool?, hidden: Bool?, team: String?, truncatedBy: StreamChatUserObject?, muteExpiresAt: Date?, type: String, members: [StreamChatChannelMember?]?) {
        self.id = id
        
        self.custom = custom
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.createdAt = createdAt
        
        self.disabled = disabled
        
        self.truncatedAt = truncatedAt
        
        self.updatedAt = updatedAt
        
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.cooldown = cooldown
        
        self.createdBy = createdBy
        
        self.memberCount = memberCount
        
        self.ownCapabilities = ownCapabilities
        
        self.cid = cid
        
        self.frozen = frozen
        
        self.hideMessagesBefore = hideMessagesBefore
        
        self.config = config
        
        self.deletedAt = deletedAt
        
        self.lastMessageAt = lastMessageAt
        
        self.muted = muted
        
        self.hidden = hidden
        
        self.team = team
        
        self.truncatedBy = truncatedBy
        
        self.muteExpiresAt = muteExpiresAt
        
        self.type = type
        
        self.members = members
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        
        case custom
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case createdAt = "created_at"
        
        case disabled
        
        case truncatedAt = "truncated_at"
        
        case updatedAt = "updated_at"
        
        case autoTranslationLanguage = "auto_translation_language"
        
        case cooldown
        
        case createdBy = "created_by"
        
        case memberCount = "member_count"
        
        case ownCapabilities = "own_capabilities"
        
        case cid
        
        case frozen
        
        case hideMessagesBefore = "hide_messages_before"
        
        case config
        
        case deletedAt = "deleted_at"
        
        case lastMessageAt = "last_message_at"
        
        case muted
        
        case hidden
        
        case team
        
        case truncatedBy = "truncated_by"
        
        case muteExpiresAt = "mute_expires_at"
        
        case type
        
        case members
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(truncatedAt, forKey: .truncatedAt)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(memberCount, forKey: .memberCount)
        
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(config, forKey: .config)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(lastMessageAt, forKey: .lastMessageAt)
        
        try container.encode(muted, forKey: .muted)
        
        try container.encode(hidden, forKey: .hidden)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(truncatedBy, forKey: .truncatedBy)
        
        try container.encode(muteExpiresAt, forKey: .muteExpiresAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(members, forKey: .members)
    }
}
