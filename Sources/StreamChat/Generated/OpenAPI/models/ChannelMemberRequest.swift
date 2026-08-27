//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class ChannelMemberRequest: Sendable, Encodable, JSONEncodable {
    /// Role of the member in the channel
    let channelRole: String?
    let custom: [String: RawJSON]?
    /// User response object
    let user: UserPayload?
    let userId: String

    init(
        channelRole: String? = nil,
        custom: [String: RawJSON]? = nil,
        user: UserPayload? = nil,
        userId: String
    ) {
        self.channelRole = channelRole
        self.custom = custom
        self.user = user
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelRole = "channel_role"
        case custom
        case user
        case userId = "user_id"
    }
}
