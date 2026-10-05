//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case createdAt = "created_at"
        case createdBy = "created_by"
        case expiration
        case reason
        case shadow
        case type
        case user
    }
}
