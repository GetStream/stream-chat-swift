//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NewLocationRequestPayload: Sendable, Encodable, JSONEncodable {
    let createdByDeviceId: String?
    let endAt: Date?
    let latitude: Double
    let longitude: Double

    init(createdByDeviceId: String? = nil, endAt: Date? = nil, latitude: Double, longitude: Double) {
        self.createdByDeviceId = createdByDeviceId
        self.endAt = endAt
        self.latitude = latitude
        self.longitude = longitude
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(createdByDeviceId, forKey: .createdByDeviceId)
        try container.encodeIfPresent(endAt, forKey: .endAt)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}
