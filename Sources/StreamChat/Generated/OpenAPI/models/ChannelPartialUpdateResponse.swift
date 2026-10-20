//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Basic channel data and the complete custom data after a partial update.
final class ChannelPartialUpdateResponse: Sendable, Decodable {
    /// Channel CID (<type>:<id>)
    let cid: ChannelId
    /// Custom data for this object
    let custom: [String: RawJSON]
    /// Whether the channel is disabled
    let disabled: Bool
    /// Whether the channel is frozen
    let frozen: Bool
    /// Team the channel belongs to
    let team: String?
    /// Date/time of the last update
    let updatedAt: Date

    init(
        cid: ChannelId,
        custom: [String: RawJSON],
        disabled: Bool,
        frozen: Bool,
        team: String? = nil,
        updatedAt: Date
    ) {
        self.cid = cid
        self.custom = custom
        self.disabled = disabled
        self.frozen = frozen
        self.team = team
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.custom = try container.decode([String: RawJSON].self, forKey: .custom)
        self.disabled = try container.decode(Bool.self, forKey: .disabled)
        self.frozen = try container.decode(Bool.self, forKey: .frozen)
        self.team = try container.decodeIfPresent(String.self, forKey: .team)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
