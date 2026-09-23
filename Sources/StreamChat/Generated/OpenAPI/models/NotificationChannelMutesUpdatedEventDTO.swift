//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationChannelMutesUpdatedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    let me: OwnUserResponse
    /// The type of event: "notification.channel_mutes_updated" in this case
    let type: String

    init(createdAt: Date, me: OwnUserResponse, type: String = "notification.channel_mutes_updated") {
        self.createdAt = createdAt
        self.me = me
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case me
        case type
    }
}
