//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DeviceResponse: Sendable, Codable, JSONEncodable {
    /// Date/time of creation
    let createdAt: Date
    /// Device ID
    let id: String

    init(createdAt: Date, id: String) {
        self.createdAt = createdAt
        self.id = id
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case id
    }
}
