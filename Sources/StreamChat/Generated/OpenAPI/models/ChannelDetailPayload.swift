//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents channel in chat
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
        id: String,
        lastMessageAt: Date? = nil,
        memberCount: Int? = nil,
        members: [MemberPayload]? = nil,
        messageCount: Int? = nil,
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
        self.id = id
        self.lastMessageAt = lastMessageAt
        self.memberCount = memberCount
        self.members = members
        self.messageCount = messageCount
        self.ownCapabilities = ownCapabilities
        self.team = team
        self.truncatedAt = truncatedAt
        self.truncatedBy = truncatedBy
        self.type = type
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.autoTranslationEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .autoTranslationEnabled
        )
        self.autoTranslationLanguage = try container.decodeIfPresent(
            String.self,
            forKey: .autoTranslationLanguage
        )
        self.blocked = try container.decodeIfPresent(Bool.self, forKey: .blocked)
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.config = try container.decode(ChannelConfig.self, forKey: .config)
        self.cooldown = try container.decodeIfPresent(Int.self, forKey: .cooldown)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.createdBy = try container.decodeIfPresent(UserPayload.self, forKey: .createdBy)
        self.custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        self.deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        self.disabled = try container.decode(Bool.self, forKey: .disabled)
        self.filterTags = try container.decodeIfPresent([String].self, forKey: .filterTags)
        self.frozen = try container.decode(Bool.self, forKey: .frozen)
        self.hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden)
        self.id = try container.decode(String.self, forKey: .id)
        self.lastMessageAt = try container.decodeIfPresent(Date.self, forKey: .lastMessageAt)
        self.memberCount = try container.decodeIfPresent(Int.self, forKey: .memberCount)
        self.members = try container.decodeArrayIfPresentIgnoringFailures(
            [MemberPayload].self,
            forKey: .members
        )
        self.messageCount = try container.decodeIfPresent(Int.self, forKey: .messageCount)
        self.ownCapabilities = try container.decodeIfPresent(
            [ChannelCapability].self,
            forKey: .ownCapabilities
        )
        self.team = try container.decodeIfPresent(String.self, forKey: .team)
        self.truncatedAt = try container.decodeIfPresent(Date.self, forKey: .truncatedAt)
        self.truncatedBy = try container.decodeIfPresent(UserPayload.self, forKey: .truncatedBy)
        self.type = try container.decode(String.self, forKey: .type)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
