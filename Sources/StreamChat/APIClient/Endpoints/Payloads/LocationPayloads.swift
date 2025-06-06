//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct SharedLocationPayload: Decodable {
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

struct LiveLocationUpdateRequestPayload: Encodable {
    let messageId: String
    let latitude: Double
    let longitude: Double
    let createdByDeviceId: String

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case latitude
        case longitude
        case createdByDeviceId = "created_by_device_id"
    }
}

struct StopLiveLocationRequestPayload: Encodable {
    let messageId: String
    let endAt: Date = Date()
    let createdByDeviceId: String

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case endAt = "end_at"
        case createdByDeviceId = "created_by_device_id"
    }
}

struct ActiveLiveLocationsResponsePayload: Decodable {
    let locations: [SharedLocationPayload]

    enum CodingKeys: String, CodingKey {
        case locations = "active_live_locations"
    }
}
