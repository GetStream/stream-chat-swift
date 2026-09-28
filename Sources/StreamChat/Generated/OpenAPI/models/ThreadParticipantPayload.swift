//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ThreadParticipantPayload: Sendable, Decodable {
    let channelCid: String
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let lastReadAt: Date
    let lastThreadMessageAt: Date?
    /// Left Thread At is the time when the user left the thread
    let leftThreadAt: Date?
    /// Thead ID is unique string identifier of the thread
    let threadId: String?
    /// User response object
    let user: UserPayload?
    /// User ID is unique string identifier of the user
    let userId: String?

    init(
        channelCid: String,
        createdAt: Date,
        custom: [String: RawJSON],
        lastReadAt: Date,
        lastThreadMessageAt: Date? = nil,
        leftThreadAt: Date? = nil,
        threadId: String? = nil,
        user: UserPayload? = nil,
        userId: String? = nil
    ) {
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.custom = custom
        self.lastReadAt = lastReadAt
        self.lastThreadMessageAt = lastThreadMessageAt
        self.leftThreadAt = leftThreadAt
        self.threadId = threadId
        self.user = user
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCid = "channel_cid"
        case createdAt = "created_at"
        case custom
        case lastReadAt = "last_read_at"
        case lastThreadMessageAt = "last_thread_message_at"
        case leftThreadAt = "left_thread_at"
        case threadId = "thread_id"
        case user
        case userId = "user_id"
    }
}
