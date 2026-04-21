//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PendingMessageEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var message: MessageResponse?
    /// Metadata attached to the pending message
    var metadata: [String: String]?
    /// The method used for the pending message
    var method: String
    var receivedAt: Date?
    /// The type of event: "message.pending" in this case
    var type: String = "message.pending"
    var user: UserResponse?

    init(channel: ChannelResponse? = nil, createdAt: Date, custom: [String: RawJSON], message: MessageResponse? = nil, metadata: [String: String]? = nil, method: String, receivedAt: Date? = nil, user: UserResponse? = nil) {
        self.channel = channel
        self.createdAt = createdAt
        self.custom = custom
        self.message = message
        self.metadata = metadata
        self.method = method
        self.receivedAt = receivedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case createdAt = "created_at"
        case custom
        case message
        case metadata
        case method
        case receivedAt = "received_at"
        case type
        case user
    }

    static func == (lhs: PendingMessageEvent, rhs: PendingMessageEvent) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.message == rhs.message &&
            lhs.metadata == rhs.metadata &&
            lhs.method == rhs.method &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channel)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(message)
        hasher.combine(metadata)
        hasher.combine(method)
        hasher.combine(receivedAt)
        hasher.combine(type)
        hasher.combine(user)
    }
}
