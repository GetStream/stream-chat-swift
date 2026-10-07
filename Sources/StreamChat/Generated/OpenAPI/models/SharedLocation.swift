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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channelCid = try container.decode(ChannelId.self, forKey: .channelCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.createdByDeviceId = try container.decode(DeviceId.self, forKey: .createdByDeviceId)
        self.endAt = try container.decodeIfPresent(Date.self, forKey: .endAt)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.messageId = try container.decode(MessageId.self, forKey: .messageId)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.userId = try container.decode(UserId.self, forKey: .userId)
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
