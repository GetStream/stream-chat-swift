//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class SharedLocation: Sendable, Decodable {
    public let channelCid: ChannelId
    public let createdAt: Date
    public let createdByDeviceId: DeviceId
    public let endAt: Date?
    public let latitude: Double
    public let longitude: Double
    public let messageId: MessageId
    public let updatedAt: Date
    public let userId: UserId

    init(
        channelCid: ChannelId,
        createdAt: Date,
        createdByDeviceId: DeviceId,
        endAt: Date? = nil,
        latitude: Double,
        longitude: Double,
        messageId: MessageId,
        updatedAt: Date,
        userId: UserId
    ) {
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.createdByDeviceId = createdByDeviceId
        self.endAt = endAt
        self.latitude = latitude
        self.longitude = longitude
        self.messageId = messageId
        self.updatedAt = updatedAt
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCid = "channel_cid"
        case createdAt = "created_at"
        case createdByDeviceId = "created_by_device_id"
        case endAt = "end_at"
        case latitude
        case longitude
        case messageId = "message_id"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
}

extension SharedLocation: Hashable {
    public static func == (lhs: SharedLocation, rhs: SharedLocation) -> Bool {
        lhs.channelCid == rhs.channelCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.createdByDeviceId == rhs.createdByDeviceId &&
            lhs.endAt == rhs.endAt &&
            lhs.latitude == rhs.latitude &&
            lhs.longitude == rhs.longitude &&
            lhs.messageId == rhs.messageId &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(channelCid)
        hasher.combine(createdAt)
        hasher.combine(createdByDeviceId)
        hasher.combine(endAt)
        hasher.combine(latitude)
        hasher.combine(longitude)
        hasher.combine(messageId)
        hasher.combine(updatedAt)
        hasher.combine(userId)
    }
}
