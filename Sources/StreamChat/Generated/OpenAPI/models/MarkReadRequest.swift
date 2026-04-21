//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MarkReadRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// ID of the message that is considered last read by client
    var messageId: String?
    /// Optional Thread ID to specifically mark a given thread as read
    var threadId: String?

    init(messageId: String? = nil, threadId: String? = nil) {
        self.messageId = messageId
        self.threadId = threadId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case messageId = "message_id"
        case threadId = "thread_id"
    }

    static func == (lhs: MarkReadRequest, rhs: MarkReadRequest) -> Bool {
        lhs.messageId == rhs.messageId &&
            lhs.threadId == rhs.threadId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(messageId)
        hasher.combine(threadId)
    }
}
