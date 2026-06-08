//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChannelInputRequest {
    static func dummy(
        autoTranslationEnabled: Bool? = nil,
        autoTranslationLanguage: String? = nil,
        configOverrides: ConfigOverridesRequest? = nil,
        createdBy: UserRequest? = nil,
        custom: [String: RawJSON]? = nil,
        disabled: Bool? = nil,
        frozen: Bool? = nil,
        invites: [ChannelMemberRequest]? = nil,
        members: [ChannelMemberRequest]? = nil,
        team: String? = nil
    ) -> ChannelInputRequest {
        ChannelInputRequest(
            autoTranslationEnabled: autoTranslationEnabled,
            autoTranslationLanguage: autoTranslationLanguage,
            configOverrides: configOverrides,
            createdBy: createdBy,
            custom: custom,
            disabled: disabled,
            frozen: frozen,
            invites: invites,
            members: members,
            team: team
        )
    }
}
