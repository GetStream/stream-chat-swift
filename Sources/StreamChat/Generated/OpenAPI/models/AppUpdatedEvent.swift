//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AppUpdatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var app: AppEventResponse
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var receivedAt: Date?
    /// The type of event: "app.updated" in this case
    var type: String = "app.updated"

    init(app: AppEventResponse, createdAt: Date, custom: [String: RawJSON], receivedAt: Date? = nil) {
        self.app = app
        self.createdAt = createdAt
        self.custom = custom
        self.receivedAt = receivedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case app
        case createdAt = "created_at"
        case custom
        case receivedAt = "received_at"
        case type
    }

    static func == (lhs: AppUpdatedEvent, rhs: AppUpdatedEvent) -> Bool {
        lhs.app == rhs.app &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(app)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(receivedAt)
        hasher.combine(type)
    }
}
