//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ThreadParticipantOpenAPI: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var appPk: Int
    var channelCid: String
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var lastReadAt: Date
    var lastThreadMessageAt: Date?
    /// Left Thread At is the time when the user left the thread
    var leftThreadAt: Date?
    /// Thead ID is unique string identifier of the thread
    var threadId: String?
    var user: UserResponse?
    /// User ID is unique string identifier of the user
    var userId: String?

    init(appPk: Int, channelCid: String, createdAt: Date, custom: [String: RawJSON], lastReadAt: Date, lastThreadMessageAt: Date? = nil, leftThreadAt: Date? = nil, threadId: String? = nil, user: UserResponse? = nil, userId: String? = nil) {
        self.appPk = appPk
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
        case appPk = "app_pk"
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

    static func == (lhs: ThreadParticipantOpenAPI, rhs: ThreadParticipantOpenAPI) -> Bool {
        lhs.appPk == rhs.appPk &&
            lhs.channelCid == rhs.channelCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.lastReadAt == rhs.lastReadAt &&
            lhs.lastThreadMessageAt == rhs.lastThreadMessageAt &&
            lhs.leftThreadAt == rhs.leftThreadAt &&
            lhs.threadId == rhs.threadId &&
            lhs.user == rhs.user &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(appPk)
        hasher.combine(channelCid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(lastReadAt)
        hasher.combine(lastThreadMessageAt)
        hasher.combine(leftThreadAt)
        hasher.combine(threadId)
        hasher.combine(user)
        hasher.combine(userId)
    }
}
