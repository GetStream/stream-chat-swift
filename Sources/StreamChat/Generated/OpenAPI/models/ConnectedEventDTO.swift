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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.connectionId = try container.decode(String.self, forKey: .connectionId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.me = try container.decode(OwnUserResponse.self, forKey: .me)
        self.type = try container.decode(String.self, forKey: .type)
    }
}
