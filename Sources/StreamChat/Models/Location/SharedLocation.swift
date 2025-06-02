//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SharedLocation: Equatable {
    /// The ID of the message that the location is attached to.
    public let messageId: MessageId
    /// The ID of the channel that the location is attached to.
    public let channelId: ChannelId
    /// The ID of the device that created the location.
    public let createdByDeviceId: DeviceId
    /// The latitude of the location.
    public let latitude: Double
    /// The longitude of the location.
    public let longitude: Double
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
        latitude: Double,
        longitude: Double,
        endAt: Date?,
        createdByDeviceId: DeviceId
    ) {
        self.messageId = messageId
        self.channelId = channelId
        self.latitude = latitude
        self.longitude = longitude
        self.endAt = endAt
        self.createdByDeviceId = createdByDeviceId
    }
}
