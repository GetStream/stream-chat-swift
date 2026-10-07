//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// This event is sent when a user gets banned. The event contains information about the user that was banned.
final class UserBannedEventDTO: Sendable, Event, Decodable {
    /// The CID of the channel where the target user was banned
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    let createdBy: UserPayload?
    /// The expiration date of the ban
    let expiration: Date?
    /// The reason for the ban
    let reason: String?
    /// Whether the user was shadow banned
    let shadow: Bool?
    /// The type of event: "user.banned" in this case
    let type: String
    let user: UserPayload

    init(
        cid: ChannelId? = nil,
        createdAt: Date,
        createdBy: UserPayload? = nil,
        expiration: Date? = nil,
        reason: String? = nil,
        shadow: Bool? = nil,
        type: String = "user.banned",
        user: UserPayload
    ) {
        self.cid = cid
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.expiration = expiration
        self.reason = reason
        self.shadow = shadow
        self.type = type
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.cid = try container.decodeIfPresent(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.createdBy = try container.decodeIfPresent(UserPayload.self, forKey: .createdBy)
        self.expiration = try container.decodeIfPresent(Date.self, forKey: .expiration)
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
        self.shadow = try container.decodeIfPresent(Bool.self, forKey: .shadow)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decode(UserPayload.self, forKey: .user)
    }
}
