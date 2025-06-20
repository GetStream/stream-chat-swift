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
        latitude: Double,
        longitude: Double,
        endAt: Date? = nil,
        createdByDeviceId: DeviceId = .unique
    ) -> SharedLocationPayload {
        .init(
            channelId: channelId.rawValue,
            messageId: messageId,
            latitude: latitude,
            longitude: longitude,
            endAt: endAt,
            createdByDeviceId: createdByDeviceId
        )
    }
}
