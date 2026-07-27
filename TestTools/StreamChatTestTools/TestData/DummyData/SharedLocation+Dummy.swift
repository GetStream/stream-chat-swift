//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension SharedLocation {
    static func dummy(
        channelId: ChannelId = .unique,
        createdAt: Date = .unique,
        createdByDeviceId: DeviceId = .unique,
        endAt: Date? = nil,
        latitude: Double,
        longitude: Double,
        messageId: String = .unique,
        updatedAt: Date = .unique,
        userId: UserId = .unique
    ) -> SharedLocation {
        .init(
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

extension SharedLocationsResponse {
    static func dummy(
        activeLiveLocations: [SharedLocation] = []
    ) -> SharedLocationsResponse {
        .init(
            activeLiveLocations: activeLiveLocations
        )
    }
}
