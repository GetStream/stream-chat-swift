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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case invites
        case members
        case team
    }
}
