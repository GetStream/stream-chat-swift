//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateMemberPartialResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channelMember: ChannelMemberResponse?
    /// Duration of the request in milliseconds
    var duration: String

    init(channelMember: ChannelMemberResponse? = nil, duration: String) {
        self.channelMember = channelMember
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelMember = "channel_member"
        case duration
    }

    static func == (lhs: UpdateMemberPartialResponse, rhs: UpdateMemberPartialResponse) -> Bool {
        lhs.channelMember == rhs.channelMember &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelMember)
        hasher.combine(duration)
    }
}
