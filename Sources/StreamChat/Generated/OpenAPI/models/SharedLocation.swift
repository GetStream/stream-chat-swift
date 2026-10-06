//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class SharedLocation: Sendable, Decodable {
    /// The CID (type:id) of the channel that the location is attached to.
    public let channelCid: ChannelId
    /// The date when the location was created.
    public let createdAt: Date
    /// The ID of the device that created the location.
    public let createdByDeviceId: DeviceId
    /// The date when the location sharing ends.
    /// If it's empty, it means the location sharing is static instead of live.
    public let endAt: Date?
    /// The latitude of the location.
    public let latitude: Double
    /// The longitude of the location.
    public let longitude: Double
    /// The ID of the message that the location is attached to.
    public let messageId: MessageId
    /// The date when the location was updated.
    public let updatedAt: Date
    /// The ID of the user that created the location.
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
