//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SharedLocation: Equatable {
    /// The ID of the message that the location is attached to.
    public let messageId: MessageId
    /// The ID of the channel that the location is attached to.
    public let channelId: ChannelId
    /// The ID of the user that created the location.
    public let userId: UserId
    /// The ID of the device that created the location.
    public let createdByDeviceId: DeviceId
    /// The latitude of the location.
    public let latitude: Double
    /// The longitude of the location.
    public let longitude: Double
    /// The date when the location was updated.
    public let updatedAt: Date
    /// The date when the location was created.
    public let createdAt: Date
    /// The date when the location sharing ends.
    /// If it's `nil`, it means the location sharing is static instead of live.
    public let endAt: Date?

    /// Whether the location sharing is live or not.
    public var isLive: Bool {
        endAt != nil
    }

    /// Whether the live location sharing is currently active.
    public var isLiveSharingActive: Bool {
        guard let endAt else { return false }
        return endAt > Date()
    }

    public init(
        messageId: MessageId,
        channelId: ChannelId,
        userId: UserId,
        createdByDeviceId: DeviceId,
        latitude: Double,
        longitude: Double,
        updatedAt: Date,
        createdAt: Date,
        endAt: Date?
    ) {
        self.messageId = messageId
        self.channelId = channelId
        self.userId = userId
        self.createdByDeviceId = createdByDeviceId
        self.latitude = latitude
        self.longitude = longitude
        self.updatedAt = updatedAt
        self.createdAt = createdAt
        self.endAt = endAt
    }
}
