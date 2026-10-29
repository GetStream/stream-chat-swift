//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BanRequest: Sendable, Encodable, JSONEncodable {
    /// Channel where the ban applies
    let channelCid: String?
    /// Optional explanation for the ban
    let reason: String?
    /// Whether this is a shadow ban
    let shadow: Bool?
    /// ID of the user to ban
    let targetUserId: String
    /// Duration of the ban in minutes
    let timeout: Int?

    init(
        channelCid: String? = nil,
        reason: String? = nil,
        shadow: Bool? = nil,
        targetUserId: String,
        timeout: Int? = nil
    ) {
        self.channelCid = channelCid
        self.reason = reason
        self.shadow = shadow
        self.targetUserId = targetUserId
        self.timeout = timeout
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(channelCid, forKey: .channelCid)
        try container.encodeIfPresent(reason, forKey: .reason)
        try container.encodeIfPresent(shadow, forKey: .shadow)
        try container.encode(targetUserId, forKey: .targetUserId)
        try container.encodeIfPresent(timeout, forKey: .timeout)
    }
}
