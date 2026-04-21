//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class TruncateChannelRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Permanently delete channel data (messages, reactions, etc.)
    var hardDelete: Bool?
    /// List of member IDs to hide message history for. If empty, truncates the channel for all members
    var memberIds: [String]?
    var message: MessageRequest?
    /// When `message` is set disables all push notifications for it
    var skipPush: Bool?
    /// Truncate channel data up to `truncated_at`. The system message (if provided) creation time is always greater than `truncated_at`
    var truncatedAt: Date?

    init(hardDelete: Bool? = nil, memberIds: [String]? = nil, message: MessageRequest? = nil, skipPush: Bool? = nil, truncatedAt: Date? = nil) {
        self.hardDelete = hardDelete
        self.memberIds = memberIds
        self.message = message
        self.skipPush = skipPush
        self.truncatedAt = truncatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case hardDelete = "hard_delete"
        case memberIds = "member_ids"
        case message
        case skipPush = "skip_push"
        case truncatedAt = "truncated_at"
    }

    static func == (lhs: TruncateChannelRequest, rhs: TruncateChannelRequest) -> Bool {
        lhs.hardDelete == rhs.hardDelete &&
            lhs.memberIds == rhs.memberIds &&
            lhs.message == rhs.message &&
            lhs.skipPush == rhs.skipPush &&
            lhs.truncatedAt == rhs.truncatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(hardDelete)
        hasher.combine(memberIds)
        hasher.combine(message)
        hasher.combine(skipPush)
        hasher.combine(truncatedAt)
    }
}
