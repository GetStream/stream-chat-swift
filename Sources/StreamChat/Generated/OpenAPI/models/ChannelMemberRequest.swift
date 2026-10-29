//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelMemberRequest: Sendable, Encodable, JSONEncodable {
    /// Role of the member in the channel
    let channelRole: String?
    let custom: [String: RawJSON]?
    let userId: String?

    init(channelRole: String? = nil, custom: [String: RawJSON]? = nil, userId: String? = nil) {
        self.channelRole = channelRole
        self.custom = custom
        self.userId = userId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(channelRole, forKey: .channelRole)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(userId, forKey: .userId)
    }
}
