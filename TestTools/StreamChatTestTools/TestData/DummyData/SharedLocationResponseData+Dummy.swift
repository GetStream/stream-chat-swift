//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension SharedLocationResponseData {
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
        activeLiveLocations: [SharedLocationResponseData] = []
    ) -> SharedLocationsResponse {
        .init(
            activeLiveLocations: activeLiveLocations
        )
    }
}
