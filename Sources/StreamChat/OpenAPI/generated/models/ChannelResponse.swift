//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelResponse: Codable, Hashable {
    public var cid: String
    public var createdAt: Date
    public var disabled: Bool
    public var frozen: Bool
    public var id: String
    public var type: String
    public var updatedAt: Date
    public var custom: [String: RawJSON]?
    public var autoTranslationEnabled: Bool? = nil
    public var autoTranslationLanguage: String? = nil
    public var cooldown: Int? = nil
    public var deletedAt: Date? = nil
    public var hidden: Bool? = nil
    public var hideMessagesBefore: Date? = nil
    public var lastMessageAt: Date? = nil
    public var memberCount: Int? = nil
    public var muteExpiresAt: Date? = nil
    public var muted: Bool? = nil
    public var team: String? = nil
    public var truncatedAt: Date? = nil
    public var members: [ChannelMember?]? = nil
    public var ownCapabilities: [String]? = nil
    public var config: ChannelConfigWithInfo? = nil
    public var createdBy: UserObject? = nil
    public var truncatedBy: UserObject? = nil

    public init(cid: String, createdAt: Date, disabled: Bool, frozen: Bool, id: String, type: String, updatedAt: Date, custom: [String: RawJSON], autoTranslationEnabled: Bool? = nil, autoTranslationLanguage: String? = nil, cooldown: Int? = nil, deletedAt: Date? = nil, hidden: Bool? = nil, hideMessagesBefore: Date? = nil, lastMessageAt: Date? = nil, memberCount: Int? = nil, muteExpiresAt: Date? = nil, muted: Bool? = nil, team: String? = nil, truncatedAt: Date? = nil, members: [ChannelMember?]? = nil, ownCapabilities: [String]? = nil, config: ChannelConfigWithInfo? = nil, createdBy: UserObject? = nil, truncatedBy: UserObject? = nil) {
        self.cid = cid
        self.createdAt = createdAt
        self.disabled = disabled
        self.frozen = frozen
        self.id = id
        self.type = type
        self.updatedAt = updatedAt
        self.custom = custom
        self.autoTranslationEnabled = autoTranslationEnabled
        self.autoTranslationLanguage = autoTranslationLanguage
        self.cooldown = cooldown
        self.deletedAt = deletedAt
        self.hidden = hidden
        self.hideMessagesBefore = hideMessagesBefore
        self.lastMessageAt = lastMessageAt
        self.memberCount = memberCount
        self.muteExpiresAt = muteExpiresAt
        self.muted = muted
        self.team = team
        self.truncatedAt = truncatedAt
        self.members = members
        self.ownCapabilities = ownCapabilities
        self.config = config
        self.createdBy = createdBy
        self.truncatedBy = truncatedBy
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case createdAt = "created_at"
        case disabled
        case frozen
        case id
        case type
        case updatedAt = "updated_at"
        case custom
        case autoTranslationEnabled = "auto_translation_enabled"
        case autoTranslationLanguage = "auto_translation_language"
        case cooldown
        case deletedAt = "deleted_at"
        case hidden
        case hideMessagesBefore = "hide_messages_before"
        case lastMessageAt = "last_message_at"
        case memberCount = "member_count"
        case muteExpiresAt = "mute_expires_at"
        case muted
        case team
        case truncatedAt = "truncated_at"
        case members
        case ownCapabilities = "own_capabilities"
        case config
        case createdBy = "created_by"
        case truncatedBy = "truncated_by"
    }
}
