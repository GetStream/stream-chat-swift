//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelInputRequest: Sendable, Encodable, JSONEncodable {
    let custom: [String: RawJSON]?
    let invites: [ChannelMemberRequest]?
    let members: [ChannelMemberRequest]?
    let team: String?

    init(
        custom: [String: RawJSON]? = nil,
        invites: [ChannelMemberRequest]? = nil,
        members: [ChannelMemberRequest]? = nil,
        team: String? = nil
    ) {
        self.custom = custom
        self.invites = invites
        self.members = members
        self.team = team
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(invites, forKey: .invites)
        try container.encodeIfPresent(members, forKey: .members)
        try container.encodeIfPresent(team, forKey: .team)
    }
}
