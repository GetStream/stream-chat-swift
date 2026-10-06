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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
        case createdAt = "created_at"
        case error
        case type
    }
}
