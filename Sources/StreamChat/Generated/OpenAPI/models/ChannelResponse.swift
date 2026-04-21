//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Whether auto translation is enabled or not
    var autoTranslationEnabled: Bool?
    /// Language to translate to when auto translation is active
    var autoTranslationLanguage: String?
    /// Whether this channel is blocked by current user or not
    var blocked: Bool?
    /// Channel CID (<type>:<id>)
    var cid: String
    var config: ChannelConfigWithInfo?
    /// Cooldown period after sending each message
    var cooldown: Int?
    /// Date/time of creation
    var createdAt: Date
    var createdBy: UserResponse?
    /// Custom data for this object
    var custom: [String: RawJSON]
    /// Date/time of deletion
    var deletedAt: Date?
    var disabled: Bool
    /// List of filter tags associated with the channel
    var filterTags: [String]?
    /// Whether channel is frozen or not
    var frozen: Bool
    /// Whether this channel is hidden by current user or not
    var hidden: Bool?
    /// Date since when the message history is accessible
    var hideMessagesBefore: Date?
    /// Channel unique ID
    var id: String
    /// Date of the last message sent
    var lastMessageAt: Date?
    /// Number of members in the channel
    var memberCount: Int?
    /// List of channel members (max 100)
    var members: [ChannelMemberResponse]?
    /// Number of messages in the channel
    var messageCount: Int?
    /// Date of mute expiration
    var muteExpiresAt: Date?
    /// Whether this channel is muted or not
    var muted: Bool?
    /// List of channel capabilities of authenticated user
    var ownCapabilities: [ChannelOwnCapability]?
    /// Team the channel belongs to (multi-tenant only)
    var team: String?
    /// Date of the latest truncation of the channel
    var truncatedAt: Date?
    var truncatedBy: UserResponse?
    /// Type of the channel
    var type: String
    /// Date/time of the last update
    var updatedAt: Date

    init(autoTranslationEnabled: Bool? = nil, autoTranslationLanguage: String? = nil, blocked: Bool? = nil, cid: String, config: ChannelConfigWithInfo? = nil, cooldown: Int? = nil, createdAt: Date, createdBy: UserResponse? = nil, custom: [String: RawJSON], deletedAt: Date? = nil, disabled: Bool, filterTags: [String]? = nil, frozen: Bool, hidden: Bool? = nil, hideMessagesBefore: Date? = nil, id: String, lastMessageAt: Date? = nil, memberCount: Int? = nil, members: [ChannelMemberResponse]? = nil, messageCount: Int? = nil, muteExpiresAt: Date? = nil, muted: Bool? = nil, ownCapabilities: [ChannelOwnCapability]? = nil, team: String? = nil, truncatedAt: Date? = nil, truncatedBy: UserResponse? = nil, type: String, updatedAt: Date) {
        self.autoTranslationEnabled = autoTranslationEnabled
        self.autoTranslationLanguage = autoTranslationLanguage
        self.blocked = blocked
        self.cid = cid
        self.config = config
        self.cooldown = cooldown
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.custom = custom
        self.deletedAt = deletedAt
        self.disabled = disabled
        self.filterTags = filterTags
        self.frozen = frozen
        self.hidden = hidden
        self.hideMessagesBefore = hideMessagesBefore
        self.id = id
        self.lastMessageAt = lastMessageAt
        self.memberCount = memberCount
        self.members = members
        self.messageCount = messageCount
        self.muteExpiresAt = muteExpiresAt
        self.muted = muted
        self.ownCapabilities = ownCapabilities
        self.team = team
        self.truncatedAt = truncatedAt
        self.truncatedBy = truncatedBy
        self.type = type
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case autoTranslationEnabled = "auto_translation_enabled"
        case autoTranslationLanguage = "auto_translation_language"
        case blocked
        case cid
        case config
        case cooldown
        case createdAt = "created_at"
        case createdBy = "created_by"
        case custom
        case deletedAt = "deleted_at"
        case disabled
        case filterTags = "filter_tags"
        case frozen
        case hidden
        case hideMessagesBefore = "hide_messages_before"
        case id
        case lastMessageAt = "last_message_at"
        case memberCount = "member_count"
        case members
        case messageCount = "message_count"
        case muteExpiresAt = "mute_expires_at"
        case muted
        case ownCapabilities = "own_capabilities"
        case team
        case truncatedAt = "truncated_at"
        case truncatedBy = "truncated_by"
        case type
        case updatedAt = "updated_at"
    }

    static func == (lhs: ChannelResponse, rhs: ChannelResponse) -> Bool {
        lhs.autoTranslationEnabled == rhs.autoTranslationEnabled &&
            lhs.autoTranslationLanguage == rhs.autoTranslationLanguage &&
            lhs.blocked == rhs.blocked &&
            lhs.cid == rhs.cid &&
            lhs.config == rhs.config &&
            lhs.cooldown == rhs.cooldown &&
            lhs.createdAt == rhs.createdAt &&
            lhs.createdBy == rhs.createdBy &&
            lhs.custom == rhs.custom &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.disabled == rhs.disabled &&
            lhs.filterTags == rhs.filterTags &&
            lhs.frozen == rhs.frozen &&
            lhs.hidden == rhs.hidden &&
            lhs.hideMessagesBefore == rhs.hideMessagesBefore &&
            lhs.id == rhs.id &&
            lhs.lastMessageAt == rhs.lastMessageAt &&
            lhs.memberCount == rhs.memberCount &&
            lhs.members == rhs.members &&
            lhs.messageCount == rhs.messageCount &&
            lhs.muteExpiresAt == rhs.muteExpiresAt &&
            lhs.muted == rhs.muted &&
            lhs.ownCapabilities == rhs.ownCapabilities &&
            lhs.team == rhs.team &&
            lhs.truncatedAt == rhs.truncatedAt &&
            lhs.truncatedBy == rhs.truncatedBy &&
            lhs.type == rhs.type &&
            lhs.updatedAt == rhs.updatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(autoTranslationEnabled)
        hasher.combine(autoTranslationLanguage)
        hasher.combine(blocked)
        hasher.combine(cid)
        hasher.combine(config)
        hasher.combine(cooldown)
        hasher.combine(createdAt)
        hasher.combine(createdBy)
        hasher.combine(custom)
        hasher.combine(deletedAt)
        hasher.combine(disabled)
        hasher.combine(filterTags)
        hasher.combine(frozen)
        hasher.combine(hidden)
        hasher.combine(hideMessagesBefore)
        hasher.combine(id)
        hasher.combine(lastMessageAt)
        hasher.combine(memberCount)
        hasher.combine(members)
        hasher.combine(messageCount)
        hasher.combine(muteExpiresAt)
        hasher.combine(muted)
        hasher.combine(ownCapabilities)
        hasher.combine(team)
        hasher.combine(truncatedAt)
        hasher.combine(truncatedBy)
        hasher.combine(type)
        hasher.combine(updatedAt)
    }
}
