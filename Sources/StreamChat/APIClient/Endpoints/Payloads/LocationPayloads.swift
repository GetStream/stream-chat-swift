//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct NewLocationRequestPayload: Encodable {
    let latitude: Double
    let longitude: Double
    let endAt: Date?
    let createdByDeviceId: String

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case endAt = "end_at"
        case createdByDeviceId = "created_by_device_id"
    }
}
