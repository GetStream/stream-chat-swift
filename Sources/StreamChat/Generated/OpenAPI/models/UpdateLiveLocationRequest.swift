//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateLiveLocationRequest: Sendable, Codable, JSONEncodable {
    /// Time when the live location expires
    let endAt: Date?
    /// Latitude coordinate
    let latitude: Float?
    /// Longitude coordinate
    let longitude: Float?
    /// Live location ID
    let messageId: String

    init(
        endAt: Date? = nil,
        latitude: Float? = nil,
        longitude: Float? = nil,
        messageId: String
    ) {
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
}
