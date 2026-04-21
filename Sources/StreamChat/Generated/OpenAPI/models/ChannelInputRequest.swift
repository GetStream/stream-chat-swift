//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelInputRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var autoTranslationEnabled: Bool?
    var autoTranslationLanguage: String?
    var configOverrides: ConfigOverridesRequest?
    var createdBy: UserRequest?
    var custom: [String: RawJSON]?
    var disabled: Bool?
    var frozen: Bool?
    var invites: [ChannelMemberRequest]?
    var members: [ChannelMemberRequest]?
    var team: String?

    init(autoTranslationEnabled: Bool? = nil, autoTranslationLanguage: String? = nil, configOverrides: ConfigOverridesRequest? = nil, createdBy: UserRequest? = nil, custom: [String: RawJSON]? = nil, disabled: Bool? = nil, frozen: Bool? = nil, invites: [ChannelMemberRequest]? = nil, members: [ChannelMemberRequest]? = nil, team: String? = nil) {
        self.autoTranslationEnabled = autoTranslationEnabled
        self.autoTranslationLanguage = autoTranslationLanguage
        self.configOverrides = configOverrides
        self.createdBy = createdBy
        self.custom = custom
        self.disabled = disabled
        self.frozen = frozen
        self.invites = invites
        self.members = members
        self.team = team
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case autoTranslationEnabled = "auto_translation_enabled"
        case autoTranslationLanguage = "auto_translation_language"
        case configOverrides = "config_overrides"
        case createdBy = "created_by"
        case custom
        case disabled
        case frozen
        case invites
        case members
        case team
    }

    static func == (lhs: ChannelInputRequest, rhs: ChannelInputRequest) -> Bool {
        lhs.autoTranslationEnabled == rhs.autoTranslationEnabled &&
            lhs.autoTranslationLanguage == rhs.autoTranslationLanguage &&
            lhs.configOverrides == rhs.configOverrides &&
            lhs.createdBy == rhs.createdBy &&
            lhs.custom == rhs.custom &&
            lhs.disabled == rhs.disabled &&
            lhs.frozen == rhs.frozen &&
            lhs.invites == rhs.invites &&
            lhs.members == rhs.members &&
            lhs.team == rhs.team
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(autoTranslationEnabled)
        hasher.combine(autoTranslationLanguage)
        hasher.combine(configOverrides)
        hasher.combine(createdBy)
        hasher.combine(custom)
        hasher.combine(disabled)
        hasher.combine(frozen)
        hasher.combine(invites)
        hasher.combine(members)
        hasher.combine(team)
    }
}
