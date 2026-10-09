//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a user that is participating in a thread.
final class ThreadParticipantPayload: Sendable, Decodable {
    let channelCid: String
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let lastReadAt: Date
    /// Thead ID is unique string identifier of the thread
    let threadId: String?
    /// User response object
    let user: UserPayload?

    init(
        channelCid: String,
        createdAt: Date,
        custom: [String: RawJSON],
        lastReadAt: Date,
        threadId: String? = nil,
        user: UserPayload? = nil
    ) {
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.custom = custom
        self.lastReadAt = lastReadAt
        self.threadId = threadId
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channelCid = try container.decode(String.self, forKey: .channelCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        self.lastReadAt = try container.decode(Date.self, forKey: .lastReadAt)
        self.threadId = try container.decodeIfPresent(String.self, forKey: .threadId)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
    }
}
