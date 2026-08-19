//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MutedChannelPayload: Sendable, Codable, JSONEncodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// Date/time of creation
    let createdAt: Date
    /// Date/time of mute expiration
    let expires: Date?
    /// Date/time of the last update
    let updatedAt: Date
    /// User response object
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload? = nil,
        createdAt: Date,
        expires: Date? = nil,
        updatedAt: Date,
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.createdAt = createdAt
        self.expires = expires
        self.updatedAt = updatedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case createdAt = "created_at"
        case expires
        case updatedAt = "updated_at"
        case user
    }
}
