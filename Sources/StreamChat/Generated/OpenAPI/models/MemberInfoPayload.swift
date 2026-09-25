//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MemberInfoPayload: Sendable, Codable, JSONEncodable {
    /// Role of the member in the channel
    let channelRole: String
    /// Channel-member custom fields projected via `member_custom_include`
    let custom: [String: RawJSON]?
    /// Whether the user muted notifications for this channel
    let notificationsMuted: Bool

    init(channelRole: String, custom: [String: RawJSON]? = nil, notificationsMuted: Bool) {
        self.channelRole = channelRole
        self.custom = custom
        self.notificationsMuted = notificationsMuted
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelRole = "channel_role"
        case custom
        case notificationsMuted = "notifications_muted"
    }
}
