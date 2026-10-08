//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// This event is sent when the WS connection fails
final class ConnectionErrorEventDTO: Sendable, Event, Decodable {
    let connectionId: String
    let createdAt: Date
    let error: APIError
    /// The type of event: "connection.error" in this case
    let type: String

    init(connectionId: String, createdAt: Date, error: APIError, type: String = "connection.error") {
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.error = error
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.connectionId = try container.decode(String.self, forKey: .connectionId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.error = try container.decode(APIError.self, forKey: .error)
        self.type = try container.decode(String.self, forKey: .type)
    }
}
