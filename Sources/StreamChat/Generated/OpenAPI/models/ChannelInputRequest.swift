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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case autoTranslationEnabled = "auto_translation_enabled"
        case autoTranslationLanguage = "auto_translation_language"
        case custom
        case disabled
        case frozen
        case invites
        case members
        case team
    }
}
