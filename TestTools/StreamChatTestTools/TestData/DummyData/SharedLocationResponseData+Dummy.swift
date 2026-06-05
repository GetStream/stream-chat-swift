//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension SharedLocationResponseData {
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
    ) -> SharedLocationResponseData {
        .init(
            channelCid: channelId.rawValue,
            createdAt: createdAt,
            createdByDeviceId: createdByDeviceId,
            endAt: endAt,
            latitude: Float(latitude),
            longitude: Float(longitude),
            messageId: messageId,
            updatedAt: updatedAt,
            userId: userId
        )
    }
}

extension SharedLocationsResponse {
    static func dummy(
        activeLiveLocations: [SharedLocationResponseData] = [],
        duration: String = ""
    ) -> SharedLocationsResponse {
        .init(activeLiveLocations: activeLiveLocations, duration: duration)
    }
}
