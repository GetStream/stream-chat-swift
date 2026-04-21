//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SharedLocationModel: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var createdByDeviceId: String?
    var endAt: Date?
    var latitude: Float
    var longitude: Float

    init(createdByDeviceId: String? = nil, endAt: Date? = nil, latitude: Float, longitude: Float) {
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

    static func == (lhs: SharedLocationModel, rhs: SharedLocationModel) -> Bool {
        lhs.createdByDeviceId == rhs.createdByDeviceId &&
            lhs.endAt == rhs.endAt &&
            lhs.latitude == rhs.latitude &&
            lhs.longitude == rhs.longitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdByDeviceId)
        hasher.combine(endAt)
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}
