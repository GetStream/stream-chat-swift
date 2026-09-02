//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateMemberPartialResponse: Sendable, Decodable {
    let channelMember: MemberPayload?

    init(channelMember: MemberPayload? = nil) {
        self.channelMember = channelMember
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelMember = "channel_member"
    }
}
