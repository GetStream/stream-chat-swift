//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// This event is sent when the WS connection is established and authenticated, this event contains the full user object as it is stored on the server
final class ConnectedEventDTO: Sendable, Event, Decodable {
    /// The connection_id for this client
    let connectionId: String
    let createdAt: Date
    let me: OwnUserResponse
    /// The type of event: "connection.ok" in this case
    let type: String

    init(connectionId: String, createdAt: Date, me: OwnUserResponse, type: String = "connection.ok") {
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.me = me
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
        case createdAt = "created_at"
        case me
        case type
    }
}
