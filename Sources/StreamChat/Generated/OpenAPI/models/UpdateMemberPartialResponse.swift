//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateMemberPartialResponse: Sendable, Codable, JSONEncodable {
    let channelMember: MemberPayload?
    /// Duration of the request in milliseconds
    let duration: String

    init(
        channelMember: MemberPayload? = nil,
        duration: String
    ) {
        self.channelMember = channelMember
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelMember = "channel_member"
        case duration
    }
}
