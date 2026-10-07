//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateMemberPartialResponse: Sendable, Decodable {
    let channelMember: MemberPayload?

    init(channelMember: MemberPayload? = nil) {
        self.channelMember = channelMember
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channelMember = try container.decodeIfPresent(
            MemberPayload.self,
            forKey: .channelMember
        )
    }
}
