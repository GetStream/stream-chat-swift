//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MarkUnreadRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// ID of the message from where the channel is marked unread
    var messageId: String?
    /// Timestamp of the message from where the channel is marked unread
    var messageTimestamp: Date?
    /// Mark a thread unread, specify one of the thread, message timestamp, or message id
    var threadId: String?

    init(messageId: String? = nil, messageTimestamp: Date? = nil, threadId: String? = nil) {
        self.messageId = messageId
        self.messageTimestamp = messageTimestamp
        self.threadId = threadId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case messageId = "message_id"
        case messageTimestamp = "message_timestamp"
        case threadId = "thread_id"
    }

    static func == (lhs: MarkUnreadRequest, rhs: MarkUnreadRequest) -> Bool {
        lhs.messageId == rhs.messageId &&
            lhs.messageTimestamp == rhs.messageTimestamp &&
            lhs.threadId == rhs.threadId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(messageId)
        hasher.combine(messageTimestamp)
        hasher.combine(threadId)
    }
}
