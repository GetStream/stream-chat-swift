//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Channel: Codable, Hashable {
    public var autoTranslationLanguage: String
    public var cid: String
    public var createdAt: Date
    public var disabled: Bool
    public var frozen: Bool
    public var id: String
    public var type: String
    public var updatedAt: Date
    public var custom: [String: RawJSON]
    public var autoTranslationEnabled: Bool? = nil
    public var cooldown: Int? = nil
    public var deletedAt: Date? = nil
    public var lastMessageAt: Date? = nil
    public var memberCount: Int? = nil
    public var team: String? = nil
    public var invites: [ChannelMember?]? = nil
    public var members: [ChannelMember?]? = nil
    public var config: ChannelConfig? = nil
    public var configOverrides: ChannelConfig? = nil
    public var createdBy: UserObject? = nil
    public var truncatedBy: UserObject? = nil

    public init(autoTranslationLanguage: String, cid: String, createdAt: Date, disabled: Bool, frozen: Bool, id: String, type: String, updatedAt: Date, custom: [String: RawJSON], autoTranslationEnabled: Bool? = nil, cooldown: Int? = nil, deletedAt: Date? = nil, lastMessageAt: Date? = nil, memberCount: Int? = nil, team: String? = nil, invites: [ChannelMember?]? = nil, members: [ChannelMember?]? = nil, config: ChannelConfig? = nil, configOverrides: ChannelConfig? = nil, createdBy: UserObject? = nil, truncatedBy: UserObject? = nil) {
        self.autoTranslationLanguage = autoTranslationLanguage
        self.cid = cid
        self.createdAt = createdAt
        self.disabled = disabled
        self.frozen = frozen
        self.id = id
        self.type = type
        self.updatedAt = updatedAt
        self.custom = custom
        self.autoTranslationEnabled = autoTranslationEnabled
        self.cooldown = cooldown
        self.deletedAt = deletedAt
        self.lastMessageAt = lastMessageAt
        self.memberCount = memberCount
        self.team = team
        self.invites = invites
        self.members = members
        self.config = config
        self.configOverrides = configOverrides
        self.createdBy = createdBy
        self.truncatedBy = truncatedBy
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoTranslationLanguage = "auto_translation_language"
        case cid
        case createdAt = "created_at"
        case disabled
        case frozen
        case id
        case type
        case updatedAt = "updated_at"
        case custom
        case autoTranslationEnabled = "auto_translation_enabled"
        case cooldown
        case deletedAt = "deleted_at"
        case lastMessageAt = "last_message_at"
        case memberCount = "member_count"
        case team
        case invites
        case members
        case config
        case configOverrides = "config_overrides"
        case createdBy = "created_by"
        case truncatedBy = "truncated_by"
    }
}
