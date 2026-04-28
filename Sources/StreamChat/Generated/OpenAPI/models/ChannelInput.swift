//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelInput: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Enable or disable auto translation
    var autoTranslationEnabled: Bool?
    /// Switch auto translation language
    var autoTranslationLanguage: String?
    var configOverrides: ChannelConfigOpenAPI?
    var createdBy: UserRequest?
    var createdById: String?
    var custom: [String: RawJSON]?
    var disabled: Bool?
    var filterTags: [String]?
    /// Freeze or unfreeze the channel
    var frozen: Bool?
    var invites: [ChannelMemberRequest]?
    var members: [ChannelMemberRequest]?
    /// Team the channel belongs to (if multi-tenant mode is enabled)
    var team: String?
    var truncatedById: String?

    init(autoTranslationEnabled: Bool? = nil, autoTranslationLanguage: String? = nil, configOverrides: ChannelConfigOpenAPI? = nil, createdBy: UserRequest? = nil, createdById: String? = nil, custom: [String: RawJSON]? = nil, disabled: Bool? = nil, filterTags: [String]? = nil, frozen: Bool? = nil, invites: [ChannelMemberRequest]? = nil, members: [ChannelMemberRequest]? = nil, team: String? = nil, truncatedById: String? = nil) {
        self.autoTranslationEnabled = autoTranslationEnabled
        self.autoTranslationLanguage = autoTranslationLanguage
        self.configOverrides = configOverrides
        self.createdBy = createdBy
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
        case configOverrides = "config_overrides"
        case createdBy = "created_by"
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

    static func == (lhs: ChannelInput, rhs: ChannelInput) -> Bool {
        lhs.autoTranslationEnabled == rhs.autoTranslationEnabled &&
            lhs.autoTranslationLanguage == rhs.autoTranslationLanguage &&
            lhs.configOverrides == rhs.configOverrides &&
            lhs.createdBy == rhs.createdBy &&
            lhs.createdById == rhs.createdById &&
            lhs.custom == rhs.custom &&
            lhs.disabled == rhs.disabled &&
            lhs.filterTags == rhs.filterTags &&
            lhs.frozen == rhs.frozen &&
            lhs.invites == rhs.invites &&
            lhs.members == rhs.members &&
            lhs.team == rhs.team &&
            lhs.truncatedById == rhs.truncatedById
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(autoTranslationEnabled)
        hasher.combine(autoTranslationLanguage)
        hasher.combine(configOverrides)
        hasher.combine(createdBy)
        hasher.combine(createdById)
        hasher.combine(custom)
        hasher.combine(disabled)
        hasher.combine(filterTags)
        hasher.combine(frozen)
        hasher.combine(invites)
        hasher.combine(members)
        hasher.combine(team)
        hasher.combine(truncatedById)
    }
}
