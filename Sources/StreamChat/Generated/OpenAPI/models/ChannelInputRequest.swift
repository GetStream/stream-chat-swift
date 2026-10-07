//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelInputRequest: Sendable, Encodable, JSONEncodable {
    let autoTranslationEnabled: Bool?
    let autoTranslationLanguage: String?
    let custom: [String: RawJSON]?
    let disabled: Bool?
    let frozen: Bool?
    let invites: [ChannelMemberRequest]?
    let members: [ChannelMemberRequest]?
    let team: String?

    init(
        autoTranslationEnabled: Bool? = nil,
        autoTranslationLanguage: String? = nil,
        custom: [String: RawJSON]? = nil,
        disabled: Bool? = nil,
        frozen: Bool? = nil,
        invites: [ChannelMemberRequest]? = nil,
        members: [ChannelMemberRequest]? = nil,
        team: String? = nil
    ) {
        self.autoTranslationEnabled = autoTranslationEnabled
        self.autoTranslationLanguage = autoTranslationLanguage
        self.custom = custom
        self.disabled = disabled
        self.frozen = frozen
        self.invites = invites
        self.members = members
        self.team = team
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        try container.encodeIfPresent(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(disabled, forKey: .disabled)
        try container.encodeIfPresent(frozen, forKey: .frozen)
        try container.encodeIfPresent(invites, forKey: .invites)
        try container.encodeIfPresent(members, forKey: .members)
        try container.encodeIfPresent(team, forKey: .team)
    }
}
