//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SharedLocationResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse?
    /// Channel CID
    var channelCid: String
    /// Date/time of creation
    var createdAt: Date
    /// Device ID that created the live location
    var createdByDeviceId: String
    var duration: String
    /// Time when the live location expires
    var endAt: Date?
    /// Latitude coordinate
    var latitude: Float
    /// Longitude coordinate
    var longitude: Float
    var message: MessageResponse?
    /// Message ID
    var messageId: String
    /// Date/time of the last update
    var updatedAt: Date
    /// User ID
    var userId: String

    init(channel: ChannelResponse? = nil, channelCid: String, createdAt: Date, createdByDeviceId: String, duration: String, endAt: Date? = nil, latitude: Float, longitude: Float, message: MessageResponse? = nil, messageId: String, updatedAt: Date, userId: String) {
        self.channel = channel
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.createdByDeviceId = createdByDeviceId
        self.duration = duration
        self.endAt = endAt
        self.latitude = latitude
        self.longitude = longitude
        self.message = message
        self.messageId = messageId
        self.updatedAt = updatedAt
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case channelCid = "channel_cid"
        case createdAt = "created_at"
        case createdByDeviceId = "created_by_device_id"
        case duration
        case endAt = "end_at"
        case latitude
        case longitude
        case message
        case messageId = "message_id"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }

    static func == (lhs: SharedLocationResponse, rhs: SharedLocationResponse) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.channelCid == rhs.channelCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.createdByDeviceId == rhs.createdByDeviceId &&
            lhs.duration == rhs.duration &&
            lhs.endAt == rhs.endAt &&
            lhs.latitude == rhs.latitude &&
            lhs.longitude == rhs.longitude &&
            lhs.message == rhs.message &&
            lhs.messageId == rhs.messageId &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channel)
        hasher.combine(channelCid)
        hasher.combine(createdAt)
        hasher.combine(createdByDeviceId)
        hasher.combine(duration)
        hasher.combine(endAt)
        hasher.combine(latitude)
        hasher.combine(longitude)
        hasher.combine(message)
        hasher.combine(messageId)
        hasher.combine(updatedAt)
        hasher.combine(userId)
    }
}
