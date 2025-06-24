//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension SharedLocationPayload {
    /// Returns dummy draft payload with the given values.
    static func dummy(
        channelId: ChannelId = .unique,
        messageId: String = .unique,
        userId: String = .unique,
        latitude: Double,
        longitude: Double,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        endAt: Date? = nil,
        createdByDeviceId: DeviceId = .unique
    ) -> SharedLocationPayload {
        .init(
            channelId: channelId.rawValue,
            messageId: messageId,
            userId: userId,
            latitude: latitude,
            longitude: longitude,
            createdAt: createdAt,
            updatedAt: updatedAt,
            endAt: endAt,
            createdByDeviceId: createdByDeviceId
        )
    }
}
