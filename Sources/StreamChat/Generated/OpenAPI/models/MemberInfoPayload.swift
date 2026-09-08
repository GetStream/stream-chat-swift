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

    class var customExcludedKeys: Set<String> {
        Set(CodingKeys.allCases.map(\.rawValue))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channelRole = try container.decode(String.self, forKey: .channelRole)
        if let decoded = try container.decodeIfPresent([String: RawJSON]?.self, forKey: .custom) {
            custom = decoded
        } else {
            var flattened = try [String: RawJSON](from: decoder)
            flattened.removeValues(forKeys: Array(Self.customExcludedKeys))
            custom = flattened
        }
        notificationsMuted = try container.decode(Bool.self, forKey: .notificationsMuted)
    }
}
