//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class ChannelDetailPayload: Sendable, Decodable {
    /// Whether auto translation is enabled or not
    let autoTranslationEnabled: Bool?
    /// Language (or comma-separated list of languages) to translate to when auto translation is active
    let autoTranslationLanguage: String?
    /// Whether this channel is blocked by current user or not
    let blocked: Bool?
    /// Channel CID (<type>:<id>)
    let cid: ChannelId
    let config: ChannelConfig
    /// Cooldown period after sending each message
    let cooldown: Int?
    /// Date/time of creation
    let createdAt: Date
    /// User response object
    let createdBy: UserPayload?
    /// Custom data for this object
    let custom: [String: RawJSON]
    /// Date/time of deletion
    let deletedAt: Date?
    let disabled: Bool
    /// List of filter tags associated with the channel
    let filterTags: [String]?
    /// Whether channel is frozen or not
    let frozen: Bool
    /// Whether this channel is hidden by current user or not
    let hidden: Bool?
    /// Date since when the message history is accessible
    let hideMessagesBefore: Date?
    /// Channel unique ID
    let id: String
    /// Date of the last message sent
    let lastMessageAt: Date?
    /// Number of members in the channel
    let memberCount: Int?
    /// List of channel members (max 100)
    let members: [MemberPayload]?
    /// Number of messages in the channel
    let messageCount: Int?
    /// Date of mute expiration
    let muteExpiresAt: Date?
    /// Whether this channel is muted or not
    let muted: Bool?
    /// List of channel capabilities of authenticated user
    let ownCapabilities: [ChannelCapability]?
    /// Team the channel belongs to (multi-tenant only)
    let team: String?
    /// Date of the latest truncation of the channel
    let truncatedAt: Date?
    /// User response object
    let truncatedBy: UserPayload?
    /// Type of the channel
    let type: String
    /// Date/time of the last update
    let updatedAt: Date

    init(
        autoTranslationEnabled: Bool? = nil,
        autoTranslationLanguage: String? = nil,
        blocked: Bool? = nil,
        cid: ChannelId,
        config: ChannelConfig,
        cooldown: Int? = nil,
        createdAt: Date,
        createdBy: UserPayload? = nil,
        custom: [String: RawJSON],
        deletedAt: Date? = nil,
        disabled: Bool,
        filterTags: [String]? = nil,
        frozen: Bool,
        hidden: Bool? = nil,
        hideMessagesBefore: Date? = nil,
        id: String,
        lastMessageAt: Date? = nil,
        memberCount: Int? = nil,
        members: [MemberPayload]? = nil,
        messageCount: Int? = nil,
        muteExpiresAt: Date? = nil,
        muted: Bool? = nil,
        ownCapabilities: [ChannelCapability]? = nil,
        team: String? = nil,
        truncatedAt: Date? = nil,
        truncatedBy: UserPayload? = nil,
        type: String,
        updatedAt: Date
    ) {
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

    class var customExcludedKeys: Set<String> {
        Set(CodingKeys.allCases.map(\.rawValue))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        autoTranslationEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .autoTranslationEnabled
        )
        autoTranslationLanguage = try container.decodeIfPresent(
            String.self,
            forKey: .autoTranslationLanguage
        )
        blocked = try container.decodeIfPresent(Bool.self, forKey: .blocked)
        cid = try container.decode(ChannelId.self, forKey: .cid)
        config = try container.decode(ChannelConfig.self, forKey: .config)
        cooldown = try container.decodeIfPresent(Int.self, forKey: .cooldown)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        createdBy = try container.decodeIfPresent(UserPayload.self, forKey: .createdBy)
        if let decoded = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) {
            custom = decoded
        } else {
            var flattened = try [String: RawJSON](from: decoder)
            flattened.removeValues(forKeys: Array(Self.customExcludedKeys))
            custom = flattened
        }
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        disabled = try container.decode(Bool.self, forKey: .disabled)
        filterTags = try container.decodeIfPresent([String].self, forKey: .filterTags)
        frozen = try container.decode(Bool.self, forKey: .frozen)
        hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden)
        hideMessagesBefore = try container.decodeIfPresent(Date.self, forKey: .hideMessagesBefore)
        id = try container.decode(String.self, forKey: .id)
        lastMessageAt = try container.decodeIfPresent(Date.self, forKey: .lastMessageAt)
        memberCount = try container.decodeIfPresent(Int.self, forKey: .memberCount)
        members = try container.decodeIfPresent([MemberPayload].self, forKey: .members)
        messageCount = try container.decodeIfPresent(Int.self, forKey: .messageCount)
        muteExpiresAt = try container.decodeIfPresent(Date.self, forKey: .muteExpiresAt)
        muted = try container.decodeIfPresent(Bool.self, forKey: .muted)
        ownCapabilities = try container.decodeIfPresent(
            [ChannelCapability].self,
            forKey: .ownCapabilities
        )
        team = try container.decodeIfPresent(String.self, forKey: .team)
        truncatedAt = try container.decodeIfPresent(Date.self, forKey: .truncatedAt)
        truncatedBy = try container.decodeIfPresent(UserPayload.self, forKey: .truncatedBy)
        type = try container.decode(String.self, forKey: .type)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
