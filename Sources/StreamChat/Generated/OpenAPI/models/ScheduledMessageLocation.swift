//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The location a scheduled message will share
final class ScheduledMessageLocation: Sendable, Decodable {
    /// The ID of the device that created the location.
    let createdByDeviceId: String
    /// The date when the location sharing ends.
    /// If it's empty, it means the location sharing is static instead of live.
    let endAt: Date?
    /// The latitude of the location.
    let latitude: Double?
    /// The longitude of the location.
    let longitude: Double?

    init(
        createdByDeviceId: String,
        endAt: Date? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.createdByDeviceId = createdByDeviceId
        self.endAt = endAt
        self.latitude = latitude
        self.longitude = longitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdByDeviceId = try container.decode(String.self, forKey: .createdByDeviceId)
        self.endAt = try container.decodeIfPresent(Date.self, forKey: .endAt)
        self.latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
    }
}
