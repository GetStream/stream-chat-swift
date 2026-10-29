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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(channelRole, forKey: .channelRole)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encode(notificationsMuted, forKey: .notificationsMuted)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        channelRole = try container.decode(String.self, forKey: .channelRole)
        custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom)
        notificationsMuted = try container.decodeIfPresent(Bool.self, forKey: .notificationsMuted) ?? false
    }
}
