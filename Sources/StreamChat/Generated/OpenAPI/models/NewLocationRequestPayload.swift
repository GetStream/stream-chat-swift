//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NewLocationRequestPayload: Sendable, Codable, JSONEncodable {
    let createdByDeviceId: String?
    let endAt: Date?
    let latitude: Float
    let longitude: Float

    init(
        createdByDeviceId: String? = nil,
        endAt: Date? = nil,
        latitude: Float,
        longitude: Float
    ) {
        self.createdByDeviceId = createdByDeviceId
        self.endAt = endAt
        self.latitude = latitude
        self.longitude = longitude
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdByDeviceId = "created_by_device_id"
        case endAt = "end_at"
        case latitude
        case longitude
    }
}
