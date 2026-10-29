//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// This event is sent when a user gets unbanned. The event contains information about the user that was unbanned.
final class UserUnbannedEventDTO: Sendable, Event, Decodable {
    /// The CID of the channel where the target user was unbanned
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    /// The type of event: "user.unbanned" in this case
    let type: String
    let user: UserPayload

    init(cid: ChannelId? = nil, createdAt: Date, type: String = "user.unbanned", user: UserPayload) {
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.cid = try container.decodeIfPresent(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decode(UserPayload.self, forKey: .user)
    }
}
