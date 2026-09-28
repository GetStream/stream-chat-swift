//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case createdAt = "created_at"
        case type
        case user
    }
}
