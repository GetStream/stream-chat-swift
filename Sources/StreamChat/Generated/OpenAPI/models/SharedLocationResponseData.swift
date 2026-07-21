//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SharedLocationResponseData: Sendable, Codable, JSONEncodable {
    let channelCid: String
    let createdAt: Date
    let createdByDeviceId: String
    let endAt: Date?
    let latitude: Float
    let longitude: Float
    let messageId: String
    let updatedAt: Date
    let userId: String

    init(
        channelCid: String,
        createdAt: Date,
        createdByDeviceId: String,
        endAt: Date? = nil,
        latitude: Float,
        longitude: Float,
        messageId: String,
        updatedAt: Date,
        userId: String
    ) {
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.createdByDeviceId = createdByDeviceId
        self.endAt = endAt
        self.latitude = latitude
        self.longitude = longitude
        self.messageId = messageId
        self.updatedAt = updatedAt
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCid = "channel_cid"
        case createdAt = "created_at"
        case createdByDeviceId = "created_by_device_id"
        case endAt = "end_at"
        case latitude
        case longitude
        case messageId = "message_id"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
}
