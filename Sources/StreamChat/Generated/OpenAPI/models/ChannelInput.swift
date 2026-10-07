//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelInput: Sendable, Encodable, JSONEncodable {
    let custom: [String: RawJSON]?
    let filterTags: [String]?
    let invites: [ChannelMemberRequest]?
    let members: [ChannelMemberRequest]?
    /// Team the channel belongs to (if multi-tenant mode is enabled)
    let team: String?

    init(
        custom: [String: RawJSON]? = nil,
        filterTags: [String]? = nil,
        invites: [ChannelMemberRequest]? = nil,
        members: [ChannelMemberRequest]? = nil,
        team: String? = nil
    ) {
        self.custom = custom
        self.filterTags = filterTags
        self.invites = invites
        self.members = members
        self.team = team
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(filterTags, forKey: .filterTags)
        try container.encodeIfPresent(invites, forKey: .invites)
        try container.encodeIfPresent(members, forKey: .members)
        try container.encodeIfPresent(team, forKey: .team)
    }
}
