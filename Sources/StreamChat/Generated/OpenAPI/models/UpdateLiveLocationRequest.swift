//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateLiveLocationRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Time when the live location expires
    var endAt: Date?
    /// Latitude coordinate
    var latitude: Float?
    /// Longitude coordinate
    var longitude: Float?
    /// Live location ID
    var messageId: String

    init(endAt: Date? = nil, latitude: Float? = nil, longitude: Float? = nil, messageId: String) {
        self.endAt = endAt
        self.latitude = latitude
        self.longitude = longitude
        self.messageId = messageId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case endAt = "end_at"
        case latitude
        case longitude
        case messageId = "message_id"
    }

    static func == (lhs: UpdateLiveLocationRequest, rhs: UpdateLiveLocationRequest) -> Bool {
        lhs.endAt == rhs.endAt &&
            lhs.latitude == rhs.latitude &&
            lhs.longitude == rhs.longitude &&
            lhs.messageId == rhs.messageId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(endAt)
        hasher.combine(latitude)
        hasher.combine(longitude)
        hasher.combine(messageId)
    }
}
