//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct LocationPayload: Decodable {
    let channelId: String
    let messageId: String
    let latitude: Double
    let longitude: Double
    let endAt: Date?
    let createdByDeviceId: String

    enum CodingKeys: String, CodingKey {
        case channelId = "channel_cid"
        case messageId = "message_id"
        case latitude
        case longitude
        case createdByDeviceId = "created_by_device_id"
        case endAt = "end_at"
    }
}

struct LocationRequestPayload: Encodable {
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
