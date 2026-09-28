//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelInput: Sendable, Encodable, JSONEncodable {
    /// Enable or disable auto translation
    let autoTranslationEnabled: Bool?
    /// Language (or comma-separated list of languages) to translate to when auto translation is active
    let autoTranslationLanguage: String?
    let createdById: String?
    let custom: [String: RawJSON]?
    let disabled: Bool?
    let filterTags: [String]?
    /// Freeze or unfreeze the channel
    let frozen: Bool?
    let invites: [ChannelMemberRequest]?
    let members: [ChannelMemberRequest]?
    /// Team the channel belongs to (if multi-tenant mode is enabled)
    let team: String?
    let truncatedById: String?

    init(
        autoTranslationEnabled: Bool? = nil,
        autoTranslationLanguage: String? = nil,
        createdById: String? = nil,
        custom: [String: RawJSON]? = nil,
        disabled: Bool? = nil,
        filterTags: [String]? = nil,
        frozen: Bool? = nil,
        invites: [ChannelMemberRequest]? = nil,
        members: [ChannelMemberRequest]? = nil,
        team: String? = nil,
        truncatedById: String? = nil
    ) {
        self.autoTranslationEnabled = autoTranslationEnabled
        self.autoTranslationLanguage = autoTranslationLanguage
        self.createdById = createdById
        self.custom = custom
        self.disabled = disabled
        self.filterTags = filterTags
        self.frozen = frozen
        self.invites = invites
        self.members = members
        self.team = team
        self.truncatedById = truncatedById
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case autoTranslationEnabled = "auto_translation_enabled"
        case autoTranslationLanguage = "auto_translation_language"
        case createdById = "created_by_id"
        case custom
        case disabled
        case filterTags = "filter_tags"
        case frozen
        case invites
        case members
        case team
        case truncatedById = "truncated_by_id"
    }
}
