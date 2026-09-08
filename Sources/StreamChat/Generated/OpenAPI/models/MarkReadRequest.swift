//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MarkReadRequest: Sendable, Encodable, JSONEncodable {
    /// ID of the message that is considered last read by client
    let messageId: String?
    /// Optional Thread ID to specifically mark a given thread as read
    let threadId: String?

    init(messageId: String? = nil, threadId: String? = nil) {
        self.messageId = messageId
        self.threadId = threadId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case messageId = "message_id"
        case threadId = "thread_id"
    }
}
