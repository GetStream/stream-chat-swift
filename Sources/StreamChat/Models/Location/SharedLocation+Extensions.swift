//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension SharedLocation {
    /// The ID of the channel that the location is attached to.
    var channelId: ChannelId { channelCid }

    /// Whether the location sharing is live or not.
    var isLive: Bool {
        endAt != nil
    }

    /// Whether the live location sharing is currently active.
    var isLiveSharingActive: Bool {
        guard let endAt else { return false }
        return endAt > Date()
    }

    /// Creates a new `SharedLocation`.
    convenience init(
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
        self.init(
            channelCid: channelId,
            createdAt: createdAt,
            createdByDeviceId: createdByDeviceId,
            endAt: endAt,
            latitude: latitude,
            longitude: longitude,
            messageId: messageId,
            updatedAt: updatedAt,
            userId: userId
        )
    }
}
